package main

import (
	"bytes"
	"io"
	"os"
	"regexp"

	pipeline "github.com/tektoncd/pipeline/pkg/apis/pipeline/v1"
	"github.com/tektoncd/pipeline/pkg/substitution"
	"github.com/zregvart/tkn-fmt/format"
	"sigs.k8s.io/yaml"
)

func readTask(path string) (*pipeline.Task, error) {
	b := expectValue(os.ReadFile(path)) // #nosec G304 -- we want to read the file as Task, nothing to worry about here
	b = bytes.TrimLeft(b, "---\n")
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
