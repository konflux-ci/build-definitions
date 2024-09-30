package main

import (
	"bytes"
	"io"
	"os"
	"path/filepath"
	"regexp"

	pipeline "github.com/tektoncd/pipeline/pkg/apis/pipeline/v1"
	"github.com/tektoncd/pipeline/pkg/substitution"
	"github.com/zregvart/tkn-fmt/format"
	"sigs.k8s.io/kustomize/api/krusty"
	"sigs.k8s.io/kustomize/api/types"
	"sigs.k8s.io/kustomize/kyaml/filesys"
	"sigs.k8s.io/yaml"
)

func loadTask(path string) (*pipeline.Task, error) {
	if filepath.Base(path) == "kustomization.yaml" {
		return renderTask(filepath.Dir(path))
	}

	return readTask(path)
}

func readTask(path string) (*pipeline.Task, error) {
	b, err := os.ReadFile(path) // #nosec G304 -- we want to read the file as Task, nothing to worry about here
	if err != nil {
		return nil, err
	}
	b = bytes.TrimLeft(b, "---\n")
	task := pipeline.Task{}
	return &task, yaml.Unmarshal(b, &task)
}

func renderTask(path string) (*pipeline.Task, error) {
	opts := krusty.MakeDefaultOptions()
	opts.LoadRestrictions = types.LoadRestrictionsNone

	kustomize := krusty.MakeKustomizer(opts)
	result, err := kustomize.Run(filesys.MakeFsOnDisk(), path)
	if err != nil {
		return nil, err
	}

	b, err := result.AsYaml()
	if err != nil {
		return nil, err
	}

	task := pipeline.Task{}
	return &task, yaml.Unmarshal(b, &task)
}

func writeTask(task *pipeline.Task, writer io.Writer) error {
	if c, ok := writer.(io.Closer); ok {
		defer c.Close()
	}

	b, err := yaml.Marshal(task)
	if err != nil {
		return err
	}

	buf := bytes.NewBuffer(b)

	return format.Format(buf, writer)
}

func applyReplacements(in string, replacements map[string]string) string {
	return substitution.ApplyReplacements(in, replacements)
}

func applyRegexReplacements(in string, replacements map[*regexp.Regexp]string) string {
	out := in
	for ex, new := range replacements {
		out = ex.ReplaceAllString(out, new)
	}
	return out
}
