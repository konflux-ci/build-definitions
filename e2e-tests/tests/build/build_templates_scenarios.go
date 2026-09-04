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
