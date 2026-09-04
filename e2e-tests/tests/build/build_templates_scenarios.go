package build

import (
	"fmt"

	"github.com/konflux-ci/e2e-tests/pkg/constants"
	"github.com/konflux-ci/e2e-tests/pkg/utils"
)

type ComponentScenarioSpec struct {
	Name                string
	GitURL              string
	Revision            string
	DefaultBranch       string
	AuthMode            string
	ContextDir          string
	DockerFilePath      string
	PipelineBundleNames []constants.BuildPipelineType
	EnableHermetic      bool
	PrefetchInput       string
	CheckAdditionalTags bool
	ManifestMediaType   string
	OverrideMediaType   string
	WorkingDirMount     string
}

func (s ComponentScenarioSpec) DeepCopy() ComponentScenarioSpec {
	pipelineBundleNames := make([]constants.BuildPipelineType, len(s.PipelineBundleNames))
	copy(pipelineBundleNames, s.PipelineBundleNames)
	return ComponentScenarioSpec{
		Name:                s.Name,
		GitURL:              s.GitURL,
		Revision:            s.Revision,
		DefaultBranch:       s.DefaultBranch,
		AuthMode:            s.AuthMode,
		ContextDir:          s.ContextDir,
		DockerFilePath:      s.DockerFilePath,
		PipelineBundleNames: pipelineBundleNames,
		EnableHermetic:      s.EnableHermetic,
		PrefetchInput:       s.PrefetchInput,
		CheckAdditionalTags: s.CheckAdditionalTags,
		ManifestMediaType:   s.ManifestMediaType,
		OverrideMediaType:   s.OverrideMediaType,
		WorkingDirMount:     s.WorkingDirMount,
	}
}

var componentScenarios = []ComponentScenarioSpec{
	{
		Name:                "fbc",
		GitURL:              "https://github.com/konflux-qe-bd/fbc-sample-repo",
		Revision:            "8e374e107fecf03f3c64c528bb53798039661414",
		ContextDir:          "4.13",
		DockerFilePath:      "catalog.Dockerfile",
		PipelineBundleNames: []constants.BuildPipelineType{constants.FbcBuilder},
		EnableHermetic:      false,
		PrefetchInput:       "",
		ManifestMediaType:   "oci",
	},
}

func GetComponentScenarioDetailsFromGitUrl(gitUrl string) ComponentScenarioSpec {
	for _, componentScenario := range componentScenarios {
		//check repo name for both the giturls is same
		if utils.GetRepoName(componentScenario.GitURL) == utils.GetRepoName(gitUrl) {
			scenario := componentScenario.DeepCopy()
			scenario.GitURL = gitUrl
			return scenario
		}
	}
	return ComponentScenarioSpec{}
}

// this function returns which scenarios to execute based on changed_files in PR
func GetScenarios() []string {
	scenarios := utils.GetEnv(SCENARIOS_ENV, "")
	if scenarios == "" {
		fmt.Println("scenarios is empty")
		return componentUrls
	} else if scenarios == "hermetic" {
		fmt.Println("Hermeto related files changed, running hermetic scenarios as well")
		return append(basicScenarioUrls, hermeticScenarioUrls...)
	} else {
		fmt.Println("Files changed are not hermeto related, running basic scenarios")
		return basicScenarioUrls
	}
}
