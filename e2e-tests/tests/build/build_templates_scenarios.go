package build

import (
	"fmt"
	"strings"

	appservice "github.com/konflux-ci/application-api/api/v1alpha1"
	"github.com/konflux-ci/e2e-tests/pkg/constants"
	"github.com/konflux-ci/e2e-tests/pkg/framework"
	"github.com/konflux-ci/e2e-tests/pkg/utils"
	corev1 "k8s.io/api/core/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
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
		Name:                "sample-python-basic-oci",
		GitURL:              "https://github.com/konflux-qe-bd/devfile-sample-python-basic",
		Revision:            "47fc22092005aabebce233a9b6eab994a8152bbd",
		ContextDir:          ".",
		DockerFilePath:      constants.DockerFilePath,
		PipelineBundleNames: []constants.BuildPipelineType{constants.DockerBuild, constants.DockerBuildOciTA},
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
		Name:                "sample-gitlab-basic-auth",
		GitURL:              "https://gitlab.com/konflux-qe/sample-python-basic",
		Revision:            "47fc22092005aabebce233a9b6eab994a8152bbd",
		DefaultBranch:       "main",
		AuthMode:            "basic-auth",
		ContextDir:          ".",
		DockerFilePath:      constants.DockerFilePath,
		PipelineBundleNames: []constants.BuildPipelineType{constants.DockerBuildOciTAMin},
		EnableHermetic:      false,
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
		Revision:            "0060a06e9b84e5b3c24a896cb23ac865a5205ab1",
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

// CreateGitlabBuildSecret creates a Kubernetes secret for GitLab build credentials
func CreateGitlabBuildSecret(f *framework.Framework, secretName string, annotations map[string]string, token string, application *appservice.Application) error {
	ownerRef := metav1.OwnerReference{
		APIVersion: "appstudio.redhat.com/v1alpha1",
		Kind:       "Application",
		Name:       application.Name,
		UID:        application.UID,
	}
	buildSecret := corev1.Secret{
		ObjectMeta: metav1.ObjectMeta{
			Name:            secretName,
			Namespace:       f.UserNamespace,
			OwnerReferences: []metav1.OwnerReference{ownerRef},
			Labels: map[string]string{
				"appstudio.redhat.com/credentials": "scm",
				"appstudio.redhat.com/scm.host":    "gitlab.com",
			},
		},
		Type: "kubernetes.io/basic-auth",
		StringData: map[string]string{
			"password": token,
		},
	}
	if annotations != nil {
		buildSecret.Annotations = annotations
	}
	_, err := f.AsKubeAdmin.CommonController.CreateSecret(f.UserNamespace, &buildSecret)
	if err != nil {
		return fmt.Errorf("error creating build secret: %v", err)
	}
	return nil
}
