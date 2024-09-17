package main

import (
	"bytes"
	"errors"
	"fmt"
	"os"
	"path"
	"testing"

	"github.com/google/go-cmp/cmp"
	"github.com/zregvart/tkn-fmt/format"
)

func TestGolden(t *testing.T) {
	dirs, err := os.ReadDir("golden")
	if err != nil {
		t.Fatal(err)
	}

	resolveImage = func() string {
		return "quay.io/redhat-appstudio/build-trusted-artifacts:latest@sha256:resolved"
	}

	for _, dir := range dirs {
		t.Run(dir.Name(), func(t *testing.T) {
			task, err := readTask(path.Join("golden", dir.Name(), "base.yaml"))
			if err != nil {
				t.Fatal(err)
			}

			recipe, err := readRecipe(path.Join("golden", dir.Name(), "recipe.yaml"))
			if err != nil {
				t.Fatal(err)
			}

			switch dir.Name() {
			case "buildah":
				image = "" // force resolve
			case "git-clone":
				image = "quay.io/redhat-appstudio/build-trusted-artifacts:latest@sha256:existing" // use existing
			default:
				image = "quay.io/redhat-appstudio/build-trusted-artifacts:latest@sha256:placeholder"
			}

			if err := perform(task, recipe); err != nil {
				t.Fatal(err)
			}

			got := bytes.Buffer{}
			if err := writeTask(task, &got); err != nil {
				t.Fatal(err)
			}

			ta, err := os.Open(path.Join("golden", dir.Name(), "ta.yaml"))
			if err != nil {
				t.Fatal(err)
			}

			golden := bytes.Buffer{}
			if err := format.Format(ta, &golden); err != nil {
				t.Fatal(err)
			}

			expected := golden.String()

			if diff := cmp.Diff(expected, got.String()); diff != "" {
				failure := fmt.Errorf("%s mismatch (-want +got):\n%s", dir.Name(), diff)
				if err := os.WriteFile(path.Join(path.Join("golden", dir.Name(), "got")), got.Bytes(), 0644); err != nil {
					failure = errors.Join(failure, err)
				}
				if err := os.WriteFile(path.Join(path.Join("golden", dir.Name(), "expected")), golden.Bytes(), 0644); err != nil {
					failure = errors.Join(failure, err)
				}

				t.Error(failure)

			}
		})
	}
}
