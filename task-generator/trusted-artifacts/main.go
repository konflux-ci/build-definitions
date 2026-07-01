package main

import (
	"fmt"
	"os"
	"path"
	"strings"
)

func main() {
	if len(os.Args) != 2 {
		fmt.Fprintf(os.Stderr, "Usage: %s path/to/recipe.yaml\n", os.Args[0])
		os.Exit(1)
	}

	recipePath := os.Args[1]

	recipe := expectValue(readRecipe(recipePath))

	task := expectValue(loadTask(recipe.Base))

	taDir := path.Dir(recipePath)

	segments := strings.Split(recipePath, "/")
	var name string
	for i, s := range segments {
		if s == "task" && i+1 < len(segments) {
			name = segments[i+1]
			break
		}
	}
	taTaskPath := path.Join(taDir, name+".yaml")

	if _, err := os.Stat(taTaskPath); err == nil {
		existing := expectValue(readTask(taTaskPath))
		for _, step := range existing.Spec.Steps {
			if strings.Contains(step.Image, "/build-trusted-artifacts:") {
				image = step.Image
				break
			}
		}
	}

	expect(perform(task, recipe))

	expect(writeTask(task, os.Stdout))
}
