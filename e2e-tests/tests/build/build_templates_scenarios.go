package build

import (
	"fmt"
	"strings"

	"github.com/konflux-ci/e2e-tests/pkg/constants"
	"github.com/konflux-ci/e2e-tests/pkg/utils"
)

type ComponentScenarioSpec struct {
	Name                string
	GitURL              string
	Revision            string
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
		Name:                "sample-python-basic-oci",
		GitURL:              "https://github.com/konflux-qe-bd/devfile-sample-python-basic",
		Revision:            "47fc22092005aabebce233a9b6eab994a8152bbd",
		ContextDir:          ".",
		DockerFilePath:      constants.DockerFilePath,
		PipelineBundleNames: []constants.BuildPipelineType{constants.DockerBuild, constants.DockerBuildOciTA, constants.DockerBuildOciTAMin},
		EnableHermetic:      false,
		PrefetchInput:       "",
		ManifestMediaType:   "oci",
		OverrideMediaType:   "oci",
	},
	{
		Name:                "sample-python-basic-docker",
		GitURL:              "https://github.com/konflux-qe-bd/devfile-sample-python-basic-clone",
		Revision:            "47fc22092005aabebce233a9b6eab994a8152bbd",
		ContextDir:          ".",
		DockerFilePath:      constants.DockerFilePath,
		PipelineBundleNames: []constants.BuildPipelineType{constants.DockerBuild},
		EnableHermetic:      false,
		PrefetchInput:       "",
		ManifestMediaType:   "docker",
	},
	{
		Name:                "multiarch-oci",
		GitURL:              "https://github.com/konflux-qe-bd/multiarch-sample-repo",
		Revision:            "bc0452861279eb59da685ba86918938c6c9d8310",
		ContextDir:          ".",
		DockerFilePath:      "Dockerfile",
		PipelineBundleNames: []constants.BuildPipelineType{constants.DockerBuildMultiPlatformOciTa},
		EnableHermetic:      false,
		PrefetchInput:       "",
		ManifestMediaType:   "oci",
		OverrideMediaType:   "oci",
	},
	{
		Name:                "multiarch-docker",
		GitURL:              "https://github.com/konflux-qe-bd/multiarch-sample-repo-clone",
		Revision:            "bc0452861279eb59da685ba86918938c6c9d8310",
		ContextDir:          ".",
		DockerFilePath:      "Dockerfile",
		PipelineBundleNames: []constants.BuildPipelineType{constants.DockerBuildMultiPlatformOciTa},
		EnableHermetic:      false,
		PrefetchInput:       "",
		ManifestMediaType:   "docker",
	},
	{
		Name:                "prefetch-gomod",
		GitURL:              "https://github.com/konflux-qe-bd/retrodep",
		Revision:            "d8e3195d1ab9dbee1f621e3b0625a589114ac80f",
		ContextDir:          ".",
		DockerFilePath:      "Dockerfile",
		PipelineBundleNames: []constants.BuildPipelineType{constants.DockerBuild},
		EnableHermetic:      true,
		PrefetchInput:       "gomod",
		ManifestMediaType:   "docker",
	},
	{
		Name:                "prefetch-pip",
		GitURL:              "https://github.com/konflux-qe-bd/pip-e2e-test",
		Revision:            "1ecda839ba9ca55070d75c86c26a1bb07d777bba",
		ContextDir:          ".",
		DockerFilePath:      "Dockerfile",
		PipelineBundleNames: []constants.BuildPipelineType{constants.DockerBuild},
		EnableHermetic:      true,
		PrefetchInput:       "pip",
		CheckAdditionalTags: true,
		ManifestMediaType:   "docker",
	},
	{
		Name:                "prefetch-bundler",
		GitURL:              "https://github.com/konflux-qe-bd/ruby-bundler-sample-app",
		Revision:            "a38f17f2aceefcde5c8f9792b608fffdd204e3d6",
		ContextDir:          ".",
		DockerFilePath:      "Dockerfile",
		PipelineBundleNames: []constants.BuildPipelineType{constants.DockerBuild},
		EnableHermetic:      true,
		PrefetchInput:       "bundler",
		ManifestMediaType:   "docker",
	},
	{
		Name:                "prefetch-cargo",
		GitURL:              "https://github.com/konflux-qe-bd/rust-cargo-sample-app",
		Revision:            "7aed0c607c1cb6a33239135a3bab9bd6e7a66049",
		ContextDir:          ".",
		DockerFilePath:      "Dockerfile",
		PipelineBundleNames: []constants.BuildPipelineType{constants.DockerBuild},
		EnableHermetic:      true,
		PrefetchInput:       "cargo",
		ManifestMediaType:   "docker",
	},
	{
		Name:                "prefetch-npm",
		GitURL:              "https://github.com/konflux-qe-bd/nodejs-npm-sample-repo",
		Revision:            "23da12cd11784c3a25cb65445cb7ecad68e7ba25",
		ContextDir:          ".",
		DockerFilePath:      "Dockerfile",
		PipelineBundleNames: []constants.BuildPipelineType{constants.DockerBuild},
		EnableHermetic:      true,
		PrefetchInput:       "npm",
		ManifestMediaType:   "docker",
	},
	{
		Name:                "prefetch-yarn-classic",
		GitURL:              "https://github.com/konflux-qe-bd/nodejs-yarn-sample-app",
		Revision:            "20e4aad4d5ddc79f87137a4c285b4067e21aa982",
		ContextDir:          ".",
		DockerFilePath:      "Dockerfile",
		PipelineBundleNames: []constants.BuildPipelineType{constants.DockerBuild},
		EnableHermetic:      true,
		PrefetchInput:       "yarn",
		ManifestMediaType:   "docker",
	},
	{
		Name:                "prefetch-yarn-modern",
		GitURL:              "https://github.com/konflux-qe-bd/nodejs-yarn-modern-sample-app",
		Revision:            "6797f06d0eee55766929ba09361810803cafce42",
		ContextDir:          ".",
		DockerFilePath:      "Dockerfile",
		PipelineBundleNames: []constants.BuildPipelineType{constants.DockerBuild},
		EnableHermetic:      true,
		PrefetchInput:       "yarn",
		ManifestMediaType:   "docker",
	},
	{
		Name:                "prefetch-rpm",
		GitURL:              "https://github.com/konflux-qe-bd/rpm-sample-app",
		Revision:            "3a3fb169e0c8998b51d7403ba934de5c1f194b1d",
		ContextDir:          ".",
		DockerFilePath:      "Containerfile",
		PipelineBundleNames: []constants.BuildPipelineType{constants.DockerBuild},
		EnableHermetic:      true,
		PrefetchInput:       "rpm",
		ManifestMediaType:   "docker",
	},
	{
		Name:                "prefetch-generic",
		GitURL:              "https://github.com/konflux-qe-bd/generic-fetcher-sample-app",
		Revision:            "d08d8d4e79d2a2f1f1c28c55cd8fbdc6c344ca14",
		ContextDir:          ".",
		DockerFilePath:      "Dockerfile",
		PipelineBundleNames: []constants.BuildPipelineType{constants.DockerBuild},
		EnableHermetic:      true,
		PrefetchInput:       "generic",
		ManifestMediaType:   "docker",
	},
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
	{
		Name:                "from-scratch",
		GitURL:              "https://github.com/konflux-qe-bd/docker-file-from-scratch",
		Revision:            "a3ea25fc3a1523db84ff96ee9958f637aea3abcd",
		ContextDir:          ".",
		DockerFilePath:      "Containerfile",
		PipelineBundleNames: []constants.BuildPipelineType{constants.DockerBuild},
		EnableHermetic:      false,
		PrefetchInput:       "",
		ManifestMediaType:   "docker",
	},
	{
		Name:                "source-build-parent-image-with-digest-only",
		GitURL:              "https://github.com/konflux-qe-bd/source-build-parent-image-with-digest-only",
		Revision:            "a4f744581c0768eb84a4345f11d04090bb14bdff",
		ContextDir:          ".",
		DockerFilePath:      "Dockerfile",
		PipelineBundleNames: []constants.BuildPipelineType{constants.DockerBuild},
		EnableHermetic:      false,
		PrefetchInput:       "",
		ManifestMediaType:   "docker",
	},
	{
		Name:                "source-build-use-latest-parent-image",
		GitURL:              "https://github.com/konflux-qe-bd/source-build-use-latest-parent-image",
		Revision:            "b4584ac47e1df84114a10debf262b6d40f6a95f8",
		ContextDir:          ".",
		DockerFilePath:      "Dockerfile",
		PipelineBundleNames: []constants.BuildPipelineType{constants.DockerBuild},
		EnableHermetic:      false,
		PrefetchInput:       "",
		ManifestMediaType:   "docker",
	},
	{
		Name:                "source-build-parent-image-from-registry-rh-io",
		GitURL:              "https://github.com/konflux-qe-bd/source-build-parent-image-from-registry-rh-io",
		Revision:            "3f5dcac703a35dcb7b29312be72f86221d0f10ee",
		ContextDir:          ".",
		DockerFilePath:      "Dockerfile",
		PipelineBundleNames: []constants.BuildPipelineType{constants.DockerBuild},
		EnableHermetic:      false,
		PrefetchInput:       "",
		ManifestMediaType:   "docker",
	},
	{
		Name:                "source-build-base-on-konflux-image",
		GitURL:              "https://github.com/konflux-qe-bd/source-build-base-on-konflux-image",
		Revision:            "b6960c7602f21c531e3ead4df1dd1827e6f208f6",
		ContextDir:          ".",
		DockerFilePath:      "Dockerfile",
		PipelineBundleNames: []constants.BuildPipelineType{constants.DockerBuild},
		EnableHermetic:      false,
		PrefetchInput:       "",
		ManifestMediaType:   "docker",
	},
	{
		Name:                "oci-archive",
		GitURL:              "https://github.com/konflux-qe-bd/oci-archive-test",
		Revision:            "a63b71ce92cee3a8d4624ef15a232d43f93b42b9",
		ContextDir:          ".",
		DockerFilePath:      "Dockerfile",
		PipelineBundleNames: []constants.BuildPipelineType{constants.DockerBuild},
		EnableHermetic:      false,
		PrefetchInput:       "",
		WorkingDirMount:     "/buildcontext",
		ManifestMediaType:   "oci",
		OverrideMediaType:   "oci",
	},
}

func IsDockerBuildGitURL(gitURL string) bool {
	for _, componentScenario := range componentScenarios {
		//check repo name for both the giturls is same
		if utils.GetRepoName(componentScenario.GitURL) == utils.GetRepoName(gitURL) {
			for _, pipeline := range componentScenario.PipelineBundleNames {
				if !strings.HasPrefix(string(pipeline), string(constants.DockerBuild)) {
					return false
				}
			}
			return true
		}
	}
	return false
}

func IsDockerBuildPipeline(pipelineName string) bool {
	return strings.HasPrefix(pipelineName, string(constants.DockerBuild))
}

func IsFBCBuildPipeline(pipelineName string) bool {
	return pipelineName == "fbc-builder"
}

func IsDockerMinBuildPipeline(pipelineName string) bool {
	return pipelineName == "docker-build-oci-ta-min"
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

// this function returns true if hermeto related files changed, otherwise false
func DoesHermetoChanged(changedFilesStr string) bool {
	isHermetoChanged := false
	changedFiles := strings.Split(changedFilesStr, " ")
	for _, filePath := range changedFiles {
		if strings.HasPrefix(filePath, "task/buildah") || strings.HasPrefix(filePath, "task/prefetch-dependencies") {
			isHermetoChanged = true
			break
		}
	}
	return isHermetoChanged
}

// this function returns which scenarios to execute based on changed_files in PR
func GetScenarios() []string {
	changedFiles := utils.GetEnv(PR_CHANGED_FILES_ENV, "")
	if changedFiles == "" {
		fmt.Println("ChangedFiles is empty")
		return componentUrls
	} else if DoesHermetoChanged(changedFiles) {
		fmt.Println("Hermeto related files changed, running hermetic scenarios as well")
		return append(basicScenarioUrls, hermeticScenarioUrls...)
	} else {
		fmt.Println("Files changed are not hermeto related, running basic scenarios")
		return basicScenarioUrls
	}
}
