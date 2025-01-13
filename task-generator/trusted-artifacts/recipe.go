package main

import (
	"os"
	"path/filepath"
	"slices"
	"sort"

	pipeline "github.com/tektoncd/pipeline/pkg/apis/pipeline/v1"
	core "k8s.io/api/core/v1"
	"sigs.k8s.io/yaml"
)

type AdditionalStep struct {
	pipeline.Step
	At int `json:"at"`
}

type Recipe struct {
	Add                []string              `json:"add"`
	AddEnvironment     []core.EnvVar         `json:"addEnvironment"`
	AdditionalSteps    []AdditionalStep      `json:"additionalSteps"`
	AddParams          pipeline.ParamSpecs   `json:"addParams"`
	AddResult          []pipeline.TaskResult `json:"addResult"`
	AddVolume          []core.Volume         `json:"addVolume"`
	AddVolumeMount     []core.VolumeMount    `json:"addVolumeMount"`
	AddTAVolumeMount   []core.VolumeMount    `json:"addTAVolumeMount"`
	Base               string                `json:"base"`
	Description        string                `json:"description"`
	DisplaySuffix      string                `json:"displaySuffix"`
	PreferStepTemplate bool                  `json:"preferStepTemplate"`
	UseTAVolumeMount   bool                  `json:"useTAVolumeMount"`
	RegexReplacements  map[string]string     `json:"regexReplacements"`
	RemoveParams       []string              `json:"removeParams"`
	RemoveVolumes      []string              `json:"removeVolumes"`
	RemoveWorkspaces   []string              `json:"removeWorkspaces"`
	Replacements       map[string]string     `json:"replacements"`
	Suffix             string                `json:"suffix"`
	createCachi2       bool
	createSource       bool
	useCachi2          bool
	useSource          bool
}

func readRecipe(path string) (*Recipe, error) {
	b := expectValue(os.ReadFile(path)) // #nosec G304 -- the file is passed in by the user, this is expected

	// with defaults
	recipe := Recipe{
		Suffix:        "-oci-ta",
		DisplaySuffix: " oci trusted artifacts",
	}

	if err := yaml.Unmarshal(b, &recipe); err != nil {
		return nil, err
	}

	sort.Strings(recipe.Add)
	_, recipe.createCachi2 = slices.BinarySearch(recipe.Add, "create-cachi2")
	_, recipe.createSource = slices.BinarySearch(recipe.Add, "create-source")
	_, recipe.useCachi2 = slices.BinarySearch(recipe.Add, "use-cachi2")
	_, recipe.useSource = slices.BinarySearch(recipe.Add, "use-source")

	if !filepath.IsAbs(recipe.Base) {
		recipe.Base = filepath.Join(filepath.Dir(path), recipe.Base)
	}

	return &recipe, nil
}
