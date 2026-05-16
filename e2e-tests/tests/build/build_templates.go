package build

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"time"

	ecp "github.com/conforma/crds/api/v1alpha1"
	"github.com/devfile/library/v2/pkg/util"
	v1 "k8s.io/apiextensions-apiserver/pkg/apis/apiextensions/v1"

	appservice "github.com/konflux-ci/application-api/api/v1alpha1"
	"github.com/konflux-ci/e2e-tests/pkg/clients/common"
	"github.com/konflux-ci/e2e-tests/pkg/clients/has"
	"github.com/konflux-ci/e2e-tests/pkg/clients/ociregistry"
	"github.com/konflux-ci/e2e-tests/pkg/clients/oras"
	"github.com/konflux-ci/e2e-tests/pkg/constants"
	"github.com/konflux-ci/e2e-tests/pkg/framework"
	"github.com/konflux-ci/e2e-tests/pkg/utils"
	"github.com/konflux-ci/e2e-tests/pkg/utils/build"
	"github.com/konflux-ci/e2e-tests/pkg/utils/contract"
	"github.com/konflux-ci/e2e-tests/pkg/utils/pipeline"
	"github.com/konflux-ci/e2e-tests/pkg/utils/tekton"
	ginkgo "github.com/onsi/ginkgo/v2"
	gomega "github.com/onsi/gomega"
	"github.com/openshift/library-go/pkg/image/reference"

	tektonpipeline "github.com/tektoncd/pipeline/pkg/apis/pipeline/v1"

	"github.com/google/go-containerregistry/pkg/authn"
	"github.com/google/go-containerregistry/pkg/name"
	remoteimg "github.com/google/go-containerregistry/pkg/v1/remote"

	"k8s.io/apimachinery/pkg/api/errors"
	"k8s.io/apimachinery/pkg/runtime"
	"sigs.k8s.io/controller-runtime/pkg/client/config"
	"sigs.k8s.io/yaml"
)

var (
	ecPipelineRunTimeout = time.Duration(10 * time.Minute)
)

const pipelineCompletionRetries = 2

type TestBranches struct {
	RepoName       string
	BranchName     string
	PacBranchName  string
	BaseBranchName string
}

var pacAndBaseBranches []TestBranches

func CreateComponent(commonCtrl *common.SuiteController, ctrl *has.HasController, applicationName, componentName, namespace string, scenario ComponentScenarioSpec) error {
	var err error
	var buildPipelineAnnotation map[string]string
	var baseBranchName, pacBranchName string
	gomega.Expect(scenario.PipelineBundleNames).Should(gomega.HaveLen(1))
	pipelineBundleName := scenario.PipelineBundleNames[0]
	gomega.Expect(pipelineBundleName).ShouldNot(gomega.BeEmpty())
	customBuildBundle := getDefaultPipeline(pipelineBundleName)

	if scenario.EnableHermetic {
		//Update the docker-build pipeline bundle with param hermetic=true
		customBuildBundle, err = enableHermeticBuildInPipelineBundle(customBuildBundle, pipelineBundleName, scenario.PrefetchInput)
		if err != nil {
			return fmt.Errorf("failed to enable hermetic build in the pipeline bundle with: %v", err)
		}
	}
	if scenario.OverrideMediaType != "" {
		// Update the pipeline bundle with updating BUILDAH_FORMAT value
		customBuildBundle, err = enableDockerMediaTypeInPipelineBundle(customBuildBundle, pipelineBundleName, scenario.OverrideMediaType)
		if err != nil {
			return fmt.Errorf("failed to update BUILDAH_FORMAT in the pipeline bundle with: %v", err)
		}
	}

	if scenario.CheckAdditionalTags {
		//Update the pipeline bundle to apply additional tags
		customBuildBundle, err = applyAdditionalTagsInPipelineBundle(customBuildBundle, pipelineBundleName, additionalTags)
		if err != nil {
			return fmt.Errorf("failed to apply additinal tags in the pipeline bundle with: %v", err)
		}
	}

	if scenario.WorkingDirMount != "" {
		//Update the pipeline bundle to apply WORKINGDIR_MOUNT
		customBuildBundle, err = addWorkingDirMountInPipelineBundle(customBuildBundle, pipelineBundleName, scenario.WorkingDirMount)
		if err != nil {
			return fmt.Errorf("failed to apply WORKINGDIR_MOUNT in the pipeline bundle with: %v", err)

		}
	}

	if customBuildBundle == "" {
		// "latest" is a special value that causes the build service to consult the use one of the
		// bundles specified in the build-pipeline-config ConfigMap in the build-service Namespace.
		customBuildBundle = "latest"
	}
	buildPipelineAnnotation = map[string]string{
		"build.appstudio.openshift.io/pipeline": fmt.Sprintf(`{"name":"%s", "bundle": "%s"}`, pipelineBundleName, customBuildBundle),
	}

	baseBranchName = fmt.Sprintf("base-%s", util.GenerateRandomString(6))
	pacBranchName = constants.PaCPullRequestBranchPrefix + componentName

	if scenario.Revision == gitRepoContainsSymlinkBranchName {
		revision := symlinkBranchRevision
		err = commonCtrl.Github.CreateRef(utils.GetRepoName(scenario.GitURL), gitRepoContainsSymlinkBranchName, revision, baseBranchName)
		gomega.Expect(err).ShouldNot(gomega.HaveOccurred())
		pacAndBaseBranches = append(pacAndBaseBranches, TestBranches{
			RepoName:       utils.GetRepoName(scenario.GitURL),
			BranchName:     gitRepoContainsSymlinkBranchName,
			PacBranchName:  pacBranchName,
			BaseBranchName: baseBranchName,
		})
	} else {
		err = commonCtrl.Github.CreateRef(utils.GetRepoName(scenario.GitURL), "main", scenario.Revision, baseBranchName)
		gomega.Expect(err).ShouldNot(gomega.HaveOccurred())
		pacAndBaseBranches = append(pacAndBaseBranches, TestBranches{
			RepoName:       utils.GetRepoName(scenario.GitURL),
			BranchName:     "main",
			PacBranchName:  pacBranchName,
			BaseBranchName: baseBranchName,
		})
	}

	componentObj := appservice.ComponentSpec{
		ComponentName: componentName,
		Source: appservice.ComponentSource{
			ComponentSourceUnion: appservice.ComponentSourceUnion{
				GitSource: &appservice.GitSource{
					URL:           scenario.GitURL,
					Revision:      baseBranchName,
					Context:       scenario.ContextDir,
					DockerfileURL: scenario.DockerFilePath,
				},
			},
		},
	}

	if os.Getenv(constants.CUSTOM_BUILD_PIPELINE_BUNDLE_ENV) != "" {
		customBuildBundle := os.Getenv(constants.CUSTOM_BUILD_PIPELINE_BUNDLE_ENV)
		gomega.Expect(customBuildBundle).ShouldNot(gomega.BeEmpty())
		buildPipelineAnnotation = map[string]string{
			"build.appstudio.openshift.io/pipeline": fmt.Sprintf(`{"name":"%s", "bundle": "%s"}`, pipelineBundleName, customBuildBundle),
		}
	}
	c, err := ctrl.CreateComponentCheckImageRepository(componentObj, namespace, "", "", applicationName, false, utils.MergeMaps(constants.ComponentPaCRequestAnnotation, buildPipelineAnnotation))
	gomega.Expect(err).ShouldNot(gomega.HaveOccurred())
	gomega.Expect(c.Name).Should(gomega.Equal(componentName))

	ginkgo.GinkgoWriter.Printf("Created component for scenario %s: component: %s, repo: %s, baseBranchName: %s, pacBranchName: %s\n",
		scenario.Name, c.Name, scenario.GitURL, baseBranchName, pacBranchName)
	return nil
}

func getDefaultPipeline(pipelineBundleName constants.BuildPipelineType) string {
	switch pipelineBundleName {
	case "docker-build":
		return utils.GetEnv(constants.CUSTOM_DOCKER_BUILD_PIPELINE_BUNDLE_ENV, "quay.io/konflux-ci/tekton-catalog/pipeline-docker-build:devel")
	case "docker-build-oci-ta":
		return utils.GetEnv(constants.CUSTOM_DOCKER_BUILD_OCI_TA_PIPELINE_BUNDLE_ENV, "quay.io/konflux-ci/tekton-catalog/pipeline-docker-build-oci-ta:devel")
	case "docker-build-oci-ta-min":
		return utils.GetEnv(constants.CUSTOM_DOCKER_BUILD_OCI_TA_MIN_PIPELINE_BUNDLE_ENV, "quay.io/konflux-ci/tekton-catalog/pipeline-docker-build-oci-ta-min:devel")
	case "docker-build-multi-platform-oci-ta":
		return utils.GetEnv(constants.CUSTOM_DOCKER_BUILD_OCI_MULTI_PLATFORM_TA_PIPELINE_BUNDLE_ENV, "quay.io/konflux-ci/tekton-catalog/pipeline-docker-build-multi-platform-oci-ta:devel")
	case "fbc-builder":
		return utils.GetEnv(constants.CUSTOM_FBC_BUILDER_PIPELINE_BUNDLE_ENV, "quay.io/konflux-ci/tekton-catalog/pipeline-fbc-builder:devel")
	default:
		return ""
	}
}

func WaitForPipelineRunStarts(hub *framework.ControllerHub, applicationName, componentName, namespace string, timeout time.Duration) string {
	namespacedName := fmt.Sprintf("%s/%s", namespace, componentName)
	timeoutMsg := fmt.Sprintf(
		"timed out when waiting for the PipelineRun to start for the Component %s", namespacedName)
	var prName string
	gomega.Eventually(func() error {
		pipelineRun, err := hub.HasController.GetComponentPipelineRun(componentName, applicationName, namespace, "")
		if err != nil {
			ginkgo.GinkgoWriter.Printf("PipelineRun has not been created yet for Component %s\n", namespacedName)
			return err
		}
		if !pipelineRun.HasStarted() {
			return fmt.Errorf("pipelinerun %s/%s has not started yet", pipelineRun.GetNamespace(), pipelineRun.GetName())
		}
		err = hub.TektonController.AddFinalizerToPipelineRun(pipelineRun, constants.E2ETestFinalizerName)
		if err != nil {
			return fmt.Errorf("error while adding finalizer %q to the pipelineRun %q: %v",
				constants.E2ETestFinalizerName, pipelineRun.GetName(), err)
		}
		prName = pipelineRun.GetName()
		return nil
	}, timeout, constants.PipelineRunPollingInterval).Should(gomega.Succeed(), timeoutMsg)
	return prName
}

var _ = framework.BuildSuiteDescribe("Build templates E2E test", ginkgo.Label("build", "build-templates", "HACBS", "pipeline-service"), func() {
	var f *framework.Framework
	var err error
	ginkgo.AfterEach(framework.ReportFailure(&f))

	defer ginkgo.GinkgoRecover()
	ginkgo.Describe("HACBS pipelines", ginkgo.Ordered, ginkgo.Label("pipeline"), func() {

		var applicationName, symlinkPRunName, testNamespace string
		components := make(map[string]ComponentScenarioSpec)
		var pipelineRunsWithE2eFinalizer []string

		for _, gitUrl := range GetScenarios() {
			scenario := GetComponentScenarioDetailsFromGitUrl(gitUrl)
			gomega.Expect(scenario.PipelineBundleNames).ShouldNot(gomega.BeEmpty())
			for _, pipelineBundleName := range scenario.PipelineBundleNames {
				componentName := fmt.Sprintf("test-comp-%s", util.GenerateRandomString(4))

				s := scenario.DeepCopy()
				s.PipelineBundleNames = []constants.BuildPipelineType{pipelineBundleName}

				components[componentName] = s
			}
		}

		symlinkScenario := GetComponentScenarioDetailsFromGitUrl(pythonComponentGitHubURL)
		gomega.Expect(symlinkScenario.PipelineBundleNames).ShouldNot(gomega.BeEmpty())
		symlinkComponentName := fmt.Sprintf("test-symlink-comp-%s", util.GenerateRandomString(4))
		// Use the other value defined in componentScenarios in build_templates_scenario.go except revision and pipelineBundle
		symlinkScenario.Revision = gitRepoContainsSymlinkBranchName
		symlinkScenario.PipelineBundleNames = []constants.BuildPipelineType{constants.DockerBuild}
		symlinkScenario.OverrideMediaType = ""

		ginkgo.BeforeAll(func() {
			if os.Getenv("APP_SUFFIX") != "" {
				applicationName = fmt.Sprintf("test-app-%s", os.Getenv("APP_SUFFIX"))
			} else {
				applicationName = fmt.Sprintf("test-app-%s", util.GenerateRandomString(4))
			}

			f, err = framework.NewFramework(utils.GetGeneratedNamespace("build-e2e"))
			gomega.Expect(err).NotTo(gomega.HaveOccurred())
			gomega.Expect(f.UserNamespace).NotTo(gomega.BeNil())
			testNamespace = f.UserNamespace

			_, err = f.AsKubeAdmin.HasController.GetApplication(applicationName, testNamespace)
			// In case the app with the same name exist in the selected namespace, delete it first
			if err == nil {
				gomega.Expect(f.AsKubeAdmin.HasController.DeleteApplication(applicationName, testNamespace, false)).To(gomega.Succeed())
				gomega.Eventually(func() bool {
					_, err := f.AsKubeAdmin.HasController.GetApplication(applicationName, testNamespace)
					return errors.IsNotFound(err)
				}, time.Minute*5, time.Second*1).Should(gomega.BeTrue(), fmt.Sprintf("timed out when waiting for the app %s to be deleted in %s namespace", applicationName, testNamespace))
			}
			_, err = f.AsKubeAdmin.HasController.CreateApplication(applicationName, testNamespace)
			gomega.Expect(err).NotTo(gomega.HaveOccurred())

			for componentName, scenario := range components {
				err = CreateComponent(f.AsKubeAdmin.CommonController, f.AsKubeAdmin.HasController, applicationName, componentName, testNamespace, scenario)
				gomega.Expect(err).ShouldNot(gomega.HaveOccurred(), fmt.Sprintf("failed to create component for scenario: %s", scenario.Name))
			}
			// Create the symlink component
			err = CreateComponent(f.AsKubeAdmin.CommonController, f.AsKubeAdmin.HasController, applicationName, symlinkComponentName, testNamespace, symlinkScenario)
			gomega.Expect(err).ShouldNot(gomega.HaveOccurred(), "failed to create component for symlink scenario")

		})

		ginkgo.AfterAll(func() {
			//Remove finalizers from pipelineruns
			gomega.Eventually(func() error {
				pipelineRuns, err := f.AsKubeAdmin.HasController.GetAllPipelineRunsForApplication(applicationName, testNamespace)
				if err != nil {
					ginkgo.GinkgoWriter.Printf("error while getting pipelineruns: %v", err)
					return err
				}
				for i := 0; i < len(pipelineRuns.Items); i++ {
					if utils.Contains(pipelineRunsWithE2eFinalizer, pipelineRuns.Items[i].GetName()) {
						err = f.AsKubeAdmin.TektonController.RemoveFinalizerFromPipelineRun(&pipelineRuns.Items[i], constants.E2ETestFinalizerName)
						if err != nil {
							ginkgo.GinkgoWriter.Printf("error removing e2e test finalizer from %s : %v\n", pipelineRuns.Items[i].GetName(), err)
							return err
						}
					}
				}
				return nil
			}, time.Minute*1, time.Second*10).Should(gomega.Succeed(), "timed out when trying to remove the e2e-test finalizer from pipelineruns")
			// Do cleanup only in case the test succeeded
			if !ginkgo.CurrentSpecReport().Failed() {
				// Clean up only Application CR (Component and Pipelines are included) in case we are targeting specific namespace
				// Used e.g. in build-definitions e2e tests, where we are targeting build-templates-e2e namespace
				if os.Getenv(constants.E2E_APPLICATIONS_NAMESPACE_ENV) != "" {
					ginkgo.DeferCleanup(f.AsKubeAdmin.HasController.DeleteApplication, applicationName, testNamespace, false)
				} else {
					gomega.Eventually(func() error {
						return f.AsKubeAdmin.HasController.DeleteAllComponentsInASpecificNamespace(testNamespace, time.Minute*2)
					}, 2*time.Minute, 10*time.Second).Should(gomega.Succeed())
					gomega.Eventually(func() error {
						return f.AsKubeAdmin.HasController.DeleteAllApplicationsInASpecificNamespace(testNamespace, time.Minute*2)
					}, 2*time.Minute, 10*time.Second).Should(gomega.Succeed())
				}
			}

			//Cleanup pac and base branches
			for _, branches := range pacAndBaseBranches {
				err = f.AsKubeAdmin.CommonController.Github.DeleteRef(branches.RepoName, branches.PacBranchName)
				if err != nil {
					gomega.Expect(err.Error()).To(gomega.ContainSubstring("Reference does not exist"))
				}
				err = f.AsKubeAdmin.CommonController.Github.DeleteRef(branches.RepoName, branches.BaseBranchName)
				if err != nil {
					gomega.Expect(err.Error()).To(gomega.ContainSubstring("Reference does not exist"))
				}
			}
			//Cleanup webhook when not running for build-definitions CI
			if os.Getenv(constants.E2E_APPLICATIONS_NAMESPACE_ENV) == "" {
				for _, branches := range pacAndBaseBranches {
					gomega.Expect(build.CleanupWebhooks(f, branches.RepoName)).ShouldNot(gomega.HaveOccurred(), fmt.Sprintf("failed to cleanup webhooks for repo: %s", branches.RepoName))
				}
			}
		})

		ginkgo.It(fmt.Sprintf("triggers PipelineRun for symlink component with source URL %s with component name %s", pythonComponentGitHubURL, symlinkComponentName), ginkgo.Label(buildTemplatesTestLabel, sourceBuildTestLabel), func() {
			// Increase the timeout to 20min to help debug the issue https://issues.redhat.com/browse/STONEBLD-2981, once issue is fixed, revert to 5min
			timeout := time.Minute * 20
			symlinkPRunName = WaitForPipelineRunStarts(f.AsKubeAdmin, applicationName, symlinkComponentName, testNamespace, timeout)
			gomega.Expect(symlinkPRunName).ShouldNot(gomega.BeEmpty())
			pipelineRunsWithE2eFinalizer = append(pipelineRunsWithE2eFinalizer, symlinkPRunName)
		})

		for componentName, scenario := range components {
			componentName := componentName
			scenario := scenario
			gomega.Expect(scenario.PipelineBundleNames).Should(gomega.HaveLen(1))
			pipelineBundleName := scenario.PipelineBundleNames[0]
			ginkgo.It(fmt.Sprintf("scenario %s triggers PipelineRun for component with source URL %s and Pipeline %s", scenario.Name, scenario.GitURL, pipelineBundleName), ginkgo.Label(buildTemplatesTestLabel, sourceBuildTestLabel), func() {
				// Increase the timeout to 20min to help debug the issue https://issues.redhat.com/browse/STONEBLD-2981, once issue is fixed, revert to 5min
				timeout := time.Minute * 20
				prName := WaitForPipelineRunStarts(f.AsKubeAdmin, applicationName, componentName, testNamespace, timeout)
				gomega.Expect(prName).ShouldNot(gomega.BeEmpty())
				pipelineRunsWithE2eFinalizer = append(pipelineRunsWithE2eFinalizer, prName)
			})
		}

		for componentName, scenario := range components {
			componentName := componentName
			scenario := scenario
			gomega.Expect(scenario.PipelineBundleNames).Should(gomega.HaveLen(1))
			pipelineBundleName := scenario.PipelineBundleNames[0]
			var pr *tektonpipeline.PipelineRun

			ginkgo.Context(fmt.Sprintf("scenario %s (%s)", scenario.Name, pipelineBundleName), func() {

				ginkgo.It(fmt.Sprintf("should eventually finish successfully for component with Git source URL %s and Pipeline %s", scenario.GitURL, pipelineBundleName), ginkgo.Label(buildTemplatesTestLabel, sourceBuildTestLabel), func() {
					component, err := f.AsKubeAdmin.HasController.GetComponent(componentName, testNamespace)
					gomega.Expect(err).ShouldNot(gomega.HaveOccurred())
					gomega.Expect(f.AsKubeAdmin.HasController.WaitForComponentPipelineToBeFinished(component, "", "", "",
						f.AsKubeAdmin.TektonController, &has.RetryOptions{Retries: pipelineCompletionRetries, Always: true}, nil)).To(gomega.Succeed())

					pr, err = f.AsKubeAdmin.HasController.GetComponentPipelineRun(componentName, applicationName, testNamespace, "")
					gomega.Expect(err).ShouldNot(gomega.HaveOccurred())
					gomega.Expect(pr).ToNot(gomega.BeNil(), fmt.Sprintf("PipelineRun for the component %s/%s not found", testNamespace, componentName))
				})
				ginkgo.It("should push Dockerfile to registry", ginkgo.Label(buildTemplatesTestLabel), func() {

					if pipelineBundleName == constants.DockerBuildOciTAMin {
						ginkgo.Skip("Skipping DockerBuildOciTAMin build, which does not push Dockerfile to registry")
						return
					}

					if pipelineBundleName != constants.FbcBuilder {
						ensureOriginalDockerfileIsPushed(f.AsKubeAdmin, pr)
					}
				})

				ginkgo.It("floating tags are created successfully", ginkgo.Label(buildTemplatesTestLabel), func() {
					if !scenario.CheckAdditionalTags {
						ginkgo.Skip(fmt.Sprintf("floating tag validation is not needed for: %s", scenario.GitURL))
					}
					builtImage := build.GetBinaryImage(pr)
					gomega.Expect(builtImage).ToNot(gomega.BeEmpty(), "built image url is empty")
					builtImageRef, err := reference.Parse(builtImage)
					gomega.Expect(err).ShouldNot(gomega.HaveOccurred(),
						fmt.Sprintf("cannot parse image pullspec: %s", builtImage))
					for _, tagName := range additionalTags {
						_, err := build.GetImageTag(builtImageRef.Namespace, builtImageRef.Name, tagName)
						gomega.Expect(err).ShouldNot(gomega.HaveOccurred(),
							fmt.Sprintf("failed to get tag %s from image repo", tagName),
						)
					}
				})

				ginkgo.It("image manifest mediaType is correct", ginkgo.Label(buildTemplatesTestLabel), func() {
					builtImage := build.GetBinaryImage(pr)
					switch scenario.ManifestMediaType {
					case "docker":
						if pipelineBundleName == constants.FbcBuilder || pipelineBundleName == constants.DockerBuildMultiPlatformOciTa {
							// Check for docker.manifest.list mediaType
							gomega.Expect(build.GetBuiltImageManifestMediaType(builtImage)).Should(gomega.Equal(build.MediaTypeDockerManifestList), "mediaType of the image manifest is not of type docker.manifest.list")
						} else {
							// Check for docker.manifest mediaType
							gomega.Expect(build.GetBuiltImageManifestMediaType(builtImage)).Should(gomega.Equal(build.MediaTypeDockerManifest), "mediaType of the image manifest is not of type docker.manifest")
						}
					case "oci":
						if pipelineBundleName == constants.FbcBuilder || pipelineBundleName == constants.DockerBuildMultiPlatformOciTa {
							// Check for oci image index mediaType
							gomega.Expect(build.GetBuiltImageManifestMediaType(builtImage)).Should(gomega.Equal(build.MediaTypeOciImageIndex), "mediaType of the image manifest is not of type oci.image.index")
						} else {
							// Check for oci image manifest mediaType
							gomega.Expect(build.GetBuiltImageManifestMediaType(builtImage)).Should(gomega.Equal(build.MediaTypeOciManifest), "mediaType of the image is not of type oci.image.manifest")
						}
					default:
						ginkgo.Fail(fmt.Sprintf("Unknown ManifestMediaType value %s in scenario \n", scenario.ManifestMediaType))
					}

				})

				ginkgo.It("check for source images if enabled in pipeline", ginkgo.Label(buildTemplatesTestLabel, sourceBuildTestLabel), func() {
					pr, err = f.AsKubeAdmin.HasController.GetComponentPipelineRun(componentName, applicationName, testNamespace, "")
					gomega.Expect(err).ShouldNot(gomega.HaveOccurred())
					gomega.Expect(pr).ToNot(gomega.BeNil(), fmt.Sprintf("PipelineRun for the component %s/%s not found", testNamespace, componentName))

					if pipelineBundleName == constants.FbcBuilder {
						ginkgo.GinkgoWriter.Println("This is FBC build, which does not require source container build.")
						ginkgo.Skip(fmt.Sprintf("Skiping FBC build %s", pr.GetName()))
						return
					}

					if pipelineBundleName == constants.DockerBuildOciTAMin {
						ginkgo.GinkgoWriter.Println("This is DockerBuildOciTAMin build, which does not require source container build.")
						ginkgo.Skip(fmt.Sprintf("Skiping DockerBuildOciTAMin build %s", pr.GetName()))
						return
					}

					isSourceBuildEnabled := build.IsSourceBuildEnabled(pr)
					ginkgo.GinkgoWriter.Printf("Source build is enabled: %v\n", isSourceBuildEnabled)
					if !isSourceBuildEnabled {
						ginkgo.Skip("Skipping source image check since it is not enabled in the pipeline")
					}

					binaryImage := build.GetBinaryImage(pr)
					if binaryImage == "" {
						ginkgo.Fail("Failed to get the binary image url from pipelinerun")
					}

					binaryImageRef, err := reference.Parse(binaryImage)
					gomega.Expect(err).ShouldNot(gomega.HaveOccurred(),
						fmt.Sprintf("cannot parse binary image pullspec %s", binaryImage))

					tagInfo, err := build.GetImageTag(binaryImageRef.Namespace, binaryImageRef.Name, binaryImageRef.Tag)
					gomega.Expect(err).ShouldNot(gomega.HaveOccurred(),
						fmt.Sprintf("failed to get tag %s info for constructing source container image", binaryImageRef.Tag),
					)

					srcImageRef := reference.DockerImageReference{
						Registry:  binaryImageRef.Registry,
						Namespace: binaryImageRef.Namespace,
						Name:      binaryImageRef.Name,
						Tag:       fmt.Sprintf("%s.src", strings.Replace(tagInfo.ManifestDigest, ":", "-", 1)),
					}
					srcImage := srcImageRef.String()
					tagExists, err := build.DoesTagExistsInQuay(srcImage)
					gomega.Expect(err).ShouldNot(gomega.HaveOccurred(),
						fmt.Sprintf("failed to check existence of source container image %s", srcImage))
					gomega.Expect(tagExists).To(gomega.BeTrue(),
						fmt.Sprintf("cannot find source container image %s", srcImage))

					CheckSourceImage(srcImage, scenario.GitURL, f.AsKubeAdmin, pr)
				})

				ginkgo.When(fmt.Sprintf("Pipeline Results are stored for component with Git source URL %s and Pipeline %s", scenario.GitURL, pipelineBundleName), ginkgo.Label("pipeline"), func() {
					var resultClient *pipeline.ResultClient
					var pr *tektonpipeline.PipelineRun

					ginkgo.BeforeAll(func() {
						if os.Getenv(constants.TEST_ENVIRONMENT_ENV) == constants.UpstreamTestEnvironment {
							ginkgo.Skip("upstream test environment detected, skipping the test")
						}
						trRoute, err := f.AsKubeAdmin.CommonController.GetOpenshiftRoute("tekton-results", "tekton-results")
						gomega.Expect(err).NotTo(gomega.HaveOccurred())

						tektonResultsUrl := fmt.Sprintf("https://%s", trRoute.Spec.Host)
						restConfig, err := config.GetConfig()
						gomega.Expect(err).NotTo(gomega.HaveOccurred())

						bearerToken := restConfig.BearerToken
						if bearerToken == "" {
							ginkgo.Skip("the bearer token is empty, skipping the test")
						}
						resultClient = pipeline.NewClient(tektonResultsUrl, bearerToken)

						pr, err = f.AsKubeAdmin.HasController.GetComponentPipelineRun(componentName, applicationName, testNamespace, "")
						gomega.Expect(err).ShouldNot(gomega.HaveOccurred())
					})

					ginkgo.It("should have Pipeline Records", func() {
						records, err := resultClient.GetRecords(testNamespace, string(pr.GetUID()))
						// temporary logs due to RHTAPBUGS-213
						ginkgo.GinkgoWriter.Printf("records for PipelineRun %s:\n%s\n", pr.Name, records)
						gomega.Expect(err).NotTo(gomega.HaveOccurred(), fmt.Sprintf("got error getting records for PipelineRun %s: %v", pr.Name, err))
						gomega.Expect(records.Record).NotTo(gomega.BeEmpty(), fmt.Sprintf("No records found for PipelineRun %s", pr.Name))
					})

					// This test is disabled since logs are being stored in s3 which is not available in dev env
					ginkgo.It("should have Pipeline Logs", ginkgo.Pending, func() {
						// Verify if result is stored in Database
						// temporary logs due to RHTAPBUGS-213
						logs, err := resultClient.GetLogs(testNamespace, string(pr.GetUID()))
						ginkgo.GinkgoWriter.Printf("logs for PipelineRun %s:\n%s\n", pr.GetName(), logs)
						gomega.Expect(err).NotTo(gomega.HaveOccurred(), fmt.Sprintf("got error getting logs for PipelineRun %s: %v", pr.Name, err))

						timeout := time.Minute * 2
						interval := time.Second * 10
						// temporary timeout  due to RHTAPBUGS-213
						gomega.Eventually(func() error {
							// temporary logs due to RHTAPBUGS-213
							logs, err = resultClient.GetLogs(testNamespace, string(pr.GetUID()))
							if err != nil {
								return fmt.Errorf("failed to get logs for PipelineRun %s: %v", pr.Name, err)
							}
							ginkgo.GinkgoWriter.Printf("logs for PipelineRun %s:\n%s\n", pr.Name, logs)

							if len(logs.Record) == 0 {
								return fmt.Errorf("logs for PipelineRun %s/%s are empty", pr.GetNamespace(), pr.GetName())
							}
							return nil
						}, timeout, interval).Should(gomega.Succeed(), fmt.Sprintf("timed out when getting logs for PipelineRun %s/%s", pr.GetNamespace(), pr.GetName()))

						// Verify if result is stored in S3
						// temporary logs due to RHTAPBUGS-213
						log, err := resultClient.GetLogByName(logs.Record[0].Name)
						ginkgo.GinkgoWriter.Printf("log for record %s:\n%s\n", logs.Record[0].Name, log)
						gomega.Expect(err).NotTo(gomega.HaveOccurred(), fmt.Sprintf("got error getting log '%s' for PipelineRun %s: %v", logs.Record[0].Name, pr.GetName(), err))
						gomega.Expect(log).NotTo(gomega.BeEmpty(), fmt.Sprintf("no log content '%s' found for PipelineRun %s", logs.Record[0].Name, pr.GetName()))
					})
				})

				ginkgo.It(fmt.Sprintf("should validate tekton taskrun test results for component with Git source URL %s and Pipeline %s", scenario.GitURL, pipelineBundleName), ginkgo.Label(buildTemplatesTestLabel), func() {
					pr, err := f.AsKubeAdmin.HasController.GetComponentPipelineRun(componentName, applicationName, testNamespace, "")
					gomega.Expect(err).ShouldNot(gomega.HaveOccurred())
					gomega.Expect(build.ValidateBuildPipelineTestResults(pr, f.AsKubeAdmin.CommonController.KubeRest(), pipelineBundleName == constants.FbcBuilder, pipelineBundleName == constants.DockerBuildOciTAMin)).To(gomega.Succeed())
				})

				ginkgo.When(fmt.Sprintf("the container image for component with Git source URL %s is created and pushed to container registry", scenario.GitURL), ginkgo.Label("sbom", "slow"), func() {
					var imageWithDigest string
					var pr *tektonpipeline.PipelineRun

					ginkgo.BeforeAll(func() {
						var err error
						imageWithDigest, err = getImageWithDigest(f.AsKubeAdmin, componentName, applicationName, testNamespace)
						gomega.Expect(err).NotTo(gomega.HaveOccurred())
					})
					ginkgo.AfterAll(func() {
						if !ginkgo.CurrentSpecReport().Failed() {
							err = f.AsKubeAdmin.TektonController.RemoveFinalizerFromPipelineRun(pr, constants.E2ETestFinalizerName)
							if err != nil {
								ginkgo.GinkgoWriter.Printf("error removing e2e test finalizer from %s : %v\n", pr.GetName(), err)
							}
							err = f.AsKubeAdmin.TektonController.DeletePipelineRun(pr.GetName(), pr.GetNamespace())
							if err != nil {
								gomega.Expect(err.Error()).To(gomega.ContainSubstring("not found"))
							}
						}
					})
					ginkgo.It("verify-enterprise-contract check should pass", ginkgo.Label(buildTemplatesTestLabel), func() {
						// If the Tekton Chains controller is busy, it may take longer than usual for it
						// to sign and attest the image built in BeforeAll.
						err = f.AsKubeAdmin.TektonController.AwaitAttestationAndSignature(imageWithDigest, constants.ChainsAttestationTimeout)
						gomega.Expect(err).ToNot(gomega.HaveOccurred())

						cm, err := f.AsKubeAdmin.CommonController.GetConfigMap("ec-defaults", "enterprise-contract-service")
						gomega.Expect(err).ToNot(gomega.HaveOccurred())

						verifyECTaskBundle := cm.Data["verify_ec_task_bundle"]
						gomega.Expect(verifyECTaskBundle).ToNot(gomega.BeEmpty())

						publicSecretName := "cosign-public-key"
						publicKey, err := f.AsKubeAdmin.TektonController.GetTektonChainsPublicKey()
						gomega.Expect(err).ToNot(gomega.HaveOccurred())

						gomega.Expect(f.AsKubeAdmin.TektonController.CreateOrUpdateSigningSecret(
							publicKey, publicSecretName, testNamespace)).To(gomega.Succeed())

						defaultECP, err := f.AsKubeAdmin.TektonController.GetEnterpriseContractPolicy("default", "enterprise-contract-service")
						gomega.Expect(err).NotTo(gomega.HaveOccurred())

						ecpSource := ecp.Source{
							Config: &ecp.SourceConfig{
								Include: []string{"@redhat"},
								Exclude: []string{"cve", "hermetic_task", "labels", "trusted_task", "test", "base_image_registries.base_image_permitted:docker.io/library/ibmjava", "base_image_registries.base_image_permitted:docker.io/library/node",
									"tasks.pinned_task_refs", "tasks.required_tasks_found", "tasks.required_untrusted_task_found", "slsa_build_scripted_build.image_built_by_trusted_task", "source_image.exists",
									"sbom_spdx.allowed_package_sources:pkg:pypi/dockerfile-parse?checksum=sha256:36e4469abb0d96b0e3cd656284d5016e8a674cd57b8ebe5af64786fe63b8184d&download_url=https://github.com/containerbuildsystem/dockerfile-parse/archive/refs/tags/2.0.0.tar.gz",
									"sbom_spdx.allowed_package_sources:pkg:generic/dependency-check.zip?checksum=sha256:c5b5b9e592682b700e17c28f489fe50644ef54370edeb2c53d18b70824de1e22&download_url=https://github.com/jeremylong/DependencyCheck/releases/download/v11.1.0/dependency-check-11.1.0-release.zip"},
							},
							RuleData: &v1.JSON{Raw: []byte(`{"allowed_registry_prefixes": ["quay.io", "registry.access.redhat.com", "registry.redhat.io"], "allowed_olm_image_registry_prefixes": ["gcr.io/kubebuilder/", "quay.io"]}`)},
						}
						policy := contract.PolicySpecWithSource(defaultECP.Spec, ecpSource)

						gomega.Expect(f.AsKubeAdmin.TektonController.CreateOrUpdatePolicyConfiguration(testNamespace, policy)).To(gomega.Succeed())

						pipelineRun, err := f.AsKubeAdmin.HasController.GetComponentPipelineRun(componentName, applicationName, testNamespace, "")
						gomega.Expect(err).ToNot(gomega.HaveOccurred())

						revision := pipelineRun.Annotations["build.appstudio.redhat.com/commit_sha"]
						gomega.Expect(revision).ToNot(gomega.BeEmpty())

						generator := tekton.VerifyEnterpriseContract{
							Snapshot: appservice.SnapshotSpec{
								Application: applicationName,
								Components: []appservice.SnapshotComponent{
									{
										Name:           componentName,
										ContainerImage: imageWithDigest,
										Source: appservice.ComponentSource{
											ComponentSourceUnion: appservice.ComponentSourceUnion{
												GitSource: &appservice.GitSource{
													URL:      scenario.GitURL,
													Revision: revision,
												},
											},
										},
									},
								},
							},
							TaskBundle:          verifyECTaskBundle,
							Name:                "verify-enterprise-contract",
							Namespace:           testNamespace,
							PolicyConfiguration: "ec-policy",
							PublicKey:           fmt.Sprintf("k8s://%s/%s", testNamespace, publicSecretName),
							Strict:              true,
							EffectiveTime:       "now",
							IgnoreRekor:         true,
						}

						pr, err = f.AsKubeAdmin.TektonController.RunPipelineWithRetry(generator, testNamespace, int(ecPipelineRunTimeout.Seconds()))
						gomega.Expect(err).NotTo(gomega.HaveOccurred())

						err = f.AsKubeAdmin.TektonController.AddFinalizerToPipelineRun(pr, constants.E2ETestFinalizerName)
						gomega.Expect(err).NotTo(gomega.HaveOccurred(), fmt.Sprintf("error while adding finalizer %q to the pipelineRun %q", constants.E2ETestFinalizerName, pr.GetName()))

						gomega.Expect(f.AsKubeAdmin.TektonController.WatchPipelineRun(pr.Name, testNamespace, int(ecPipelineRunTimeout.Seconds()))).To(gomega.Succeed())

						pr, err = f.AsKubeAdmin.TektonController.GetPipelineRun(pr.Name, pr.Namespace)
						gomega.Expect(err).NotTo(gomega.HaveOccurred())

						tr, err := f.AsKubeAdmin.TektonController.GetTaskRunStatus(f.AsKubeAdmin.CommonController.KubeRest(), pr, "verify-enterprise-contract")
						gomega.Expect(err).NotTo(gomega.HaveOccurred())
						logs, err := f.AsKubeAdmin.TektonController.GetTaskRunLogs(pr.Name, "verify-enterprise-contract", pr.Namespace)
						gomega.Expect(err).NotTo(gomega.HaveOccurred())
						gomega.Expect(tekton.DidTaskRunSucceed(tr)).To(gomega.BeTrue(), fmt.Sprintf("%q pipeline failed, detailed report: \n%v\n", pr.Name, logs["step-detailed-report"]))
						gomega.Expect(tr.Status.Results).Should(
							gomega.ContainElements(tekton.MatchTaskRunResultWithJSONPathValue(constants.TektonTaskTestOutputName, "{$.result}", `["SUCCESS"]`)),
							fmt.Sprintf("detailed report:\n %v", logs["step-detailed-report"]),
						)
					})

					ginkgo.It("should have Hermeto content in the SBOM in case the build was hermetic", ginkgo.Label(buildTemplatesTestLabel), func() {
						if !scenario.EnableHermetic {
							ginkgo.Skip("Hermetic build is not enabled, skipping the test")
						}

						pr, err := f.AsKubeAdmin.HasController.GetComponentPipelineRun(componentName, applicationName, testNamespace, "")
						gomega.Expect(err).ShouldNot(gomega.HaveOccurred())
						taskRun, err := f.AsKubeAdmin.TektonController.GetTaskRunFromPipelineRun(f.AsKubeAdmin.CommonController.KubeRest(), pr, "build-container")
						gomega.Expect(err).NotTo(gomega.HaveOccurred())

						var sbomBlobUrl string

						for _, r := range taskRun.Status.Results {
							if r.Name == "SBOM_BLOB_URL" {
								sbomBlobUrl = r.Value.StringVal
							}
						}
						gomega.Expect(sbomBlobUrl).NotTo(gomega.BeEmpty())

						imageRef, err := reference.Parse(sbomBlobUrl)
						gomega.Expect(err).NotTo(gomega.HaveOccurred())

						c := ociregistry.NewOciRegistryV2Client(imageRef.Registry)

						sbom, err := build.FetchSbomFromRegistry(c, imageRef.Namespace, imageRef.Name, imageRef.ID)
						gomega.Expect(err).NotTo(gomega.HaveOccurred())

						hasHermetoPackages := false
						for _, pkg := range sbom.GetPackages() {
							if pkg.GetCreatedBy() == build.SbomPackageCreatedByHermeto {
								hasHermetoPackages = true
								break
							}
						}
						gomega.Expect(hasHermetoPackages).To(gomega.BeTrue(), "no hermeto packages found")
					})
				})

				ginkgo.Context("build-definitions ec pipelines", ginkgo.Label(buildTemplatesTestLabel), func() {
					ecPipelines := []string{
						"pipelines/enterprise-contract.yaml",
					}

					var gitRevision, gitURL, imageWithDigest string
					var defaultECP *ecp.EnterpriseContractPolicy
					var ecPipelineRun *tektonpipeline.PipelineRun

					ginkgo.BeforeAll(func() {
						// resolve the gitURL and gitRevision
						var err error
						gitURL, gitRevision, err = build.ResolveGitDetails(constants.EC_PIPELINES_REPO_URL_ENV, constants.EC_PIPELINES_REPO_REVISION_ENV)
						gomega.Expect(err).NotTo(gomega.HaveOccurred())

						// Double check that the component has finished. There's an earlier test that
						// verifies this so this should be a no-op. It is added here in order to avoid
						// unnecessary coupling of unrelated tests.
						component, err := f.AsKubeAdmin.HasController.GetComponent(componentName, testNamespace)
						gomega.Expect(err).ShouldNot(gomega.HaveOccurred())
						gomega.Expect(f.AsKubeAdmin.HasController.WaitForComponentPipelineToBeFinished(
							component, "", "", "", f.AsKubeAdmin.TektonController, &has.RetryOptions{Retries: pipelineCompletionRetries, Always: true}, nil)).To(gomega.Succeed())

						imageWithDigest, err = getImageWithDigest(f.AsKubeAdmin, componentName, applicationName, testNamespace)
						gomega.Expect(err).NotTo(gomega.HaveOccurred())

						err = f.AsKubeAdmin.TektonController.AwaitAttestationAndSignature(imageWithDigest, constants.ChainsAttestationTimeout)
						gomega.Expect(err).NotTo(gomega.HaveOccurred())
					})
					ginkgo.AfterAll(func() {
						if !ginkgo.CurrentSpecReport().Failed() {
							err = f.AsKubeAdmin.TektonController.RemoveFinalizerFromPipelineRun(ecPipelineRun, constants.E2ETestFinalizerName)
							if err != nil {
								ginkgo.GinkgoWriter.Printf("error removing e2e test finalizer from %s : %v\n", ecPipelineRun.GetName(), err)
							}
							err = f.AsKubeAdmin.TektonController.DeletePipelineRun(ecPipelineRun.Name, ecPipelineRun.Namespace)
							if err != nil {
								gomega.Expect(err.Error()).To(gomega.ContainSubstring("not found"))
							}
						}
					})

					for _, pathInRepo := range ecPipelines {
						pathInRepo := pathInRepo
						ginkgo.It(fmt.Sprintf("runs ec pipeline %s", pathInRepo), func() {
							generator := tekton.ECIntegrationTestScenario{
								Image:                       imageWithDigest,
								Namespace:                   testNamespace,
								PipelineGitURL:              gitURL,
								PipelineGitRevision:         gitRevision,
								PipelineGitPathInRepo:       pathInRepo,
								PipelinePolicyConfiguration: "ec-policy",
							}
							defaultECP, err = f.AsKubeAdmin.TektonController.GetEnterpriseContractPolicy("default", "enterprise-contract-service")
							gomega.Expect(err).NotTo(gomega.HaveOccurred())
							//exclude the slsa_source_correlated.source_code_reference_provided because snapshot doesn't get the info of source
							policy := contract.PolicySpecWithSourceConfig(
								defaultECP.Spec,
								ecp.SourceConfig{
									Include: []string{"@slsa3"},
									Exclude: []string{"slsa_source_correlated.source_code_reference_provided"},
								},
							)
							gomega.Expect(f.AsKubeAdmin.TektonController.CreateOrUpdatePolicyConfiguration(testNamespace, policy)).To(gomega.Succeed())

							ecPipelineRun, err = f.AsKubeAdmin.TektonController.RunPipelineWithRetry(generator, testNamespace, int(ecPipelineRunTimeout.Seconds()))
							gomega.Expect(err).NotTo(gomega.HaveOccurred())

							err = f.AsKubeAdmin.TektonController.AddFinalizerToPipelineRun(ecPipelineRun, constants.E2ETestFinalizerName)
							gomega.Expect(err).NotTo(gomega.HaveOccurred(), fmt.Sprintf("error while adding finalizer %q to the pipelineRun %q", constants.E2ETestFinalizerName, ecPipelineRun.GetName()))

							gomega.Expect(f.AsKubeAdmin.TektonController.WatchPipelineRun(ecPipelineRun.Name, testNamespace, int(ecPipelineRunTimeout.Seconds()))).To(gomega.Succeed())

							// Refresh our copy of the PipelineRun for latest results
							ecPipelineRun, err = f.AsKubeAdmin.TektonController.GetPipelineRun(ecPipelineRun.Name, ecPipelineRun.Namespace)
							gomega.Expect(err).NotTo(gomega.HaveOccurred())
							ginkgo.GinkgoWriter.Printf("The PipelineRun %s in namespace %s has status.conditions: \n%#v\n", ecPipelineRun.Name, ecPipelineRun.Namespace, ecPipelineRun.Status.Conditions)

							// Added log for debugging the intermittent issue
							ginkgo.GinkgoWriter.Printf("EC PipelineRun %s has labels: %+v\n", ecPipelineRun.Name, ecPipelineRun.Labels)
							// The UI uses this label to display additional information.
							gomega.Expect(ecPipelineRun.Labels["build.appstudio.redhat.com/pipeline"]).To(gomega.Equal("enterprise-contract"))

							// The UI uses this label to display additional information.
							tr, err := f.AsKubeAdmin.TektonController.GetTaskRunFromPipelineRun(f.AsKubeAdmin.CommonController.KubeRest(), ecPipelineRun, "verify")
							gomega.Expect(err).NotTo(gomega.HaveOccurred())
							ginkgo.GinkgoWriter.Printf("The TaskRun %s of PipelineRun %s  has status.conditions: \n%#v\n", tr.Name, ecPipelineRun.Name, tr.Status.Conditions)
							gomega.Expect(tr.Labels["build.appstudio.redhat.com/pipeline"]).To(gomega.Equal("enterprise-contract"))

							logs, err := f.AsKubeAdmin.TektonController.GetTaskRunLogs(ecPipelineRun.Name, "verify", ecPipelineRun.Namespace)
							gomega.Expect(err).NotTo(gomega.HaveOccurred())

							// The logs from the report step are used by the UI to display validation
							// details. Let's make sure it has valid JSON.
							reportLogs := logs["step-report-json"]
							gomega.Expect(reportLogs).NotTo(gomega.BeEmpty())
							var report any
							err = json.Unmarshal([]byte(reportLogs), &report)
							gomega.Expect(err).NotTo(gomega.HaveOccurred())

							// The logs from the summary step are used by the UI to display an overview of
							// the validation.
							summaryLogs := logs["step-summary"]
							ginkgo.GinkgoWriter.Printf("got step-summary log: %s\n", summaryLogs)
							gomega.Expect(summaryLogs).NotTo(gomega.BeEmpty())
							var summary build.TestOutput
							err = json.Unmarshal([]byte(summaryLogs), &summary)
							gomega.Expect(err).NotTo(gomega.HaveOccurred())
							gomega.Expect(summary).NotTo(gomega.Equal(build.TestOutput{}))
						})
					}
				})

			})
		}

		ginkgo.It(fmt.Sprintf("pipelineRun should fail for symlink component with Git source URL %s with component name %s", pythonComponentGitHubURL, symlinkComponentName), ginkgo.Label(buildTemplatesTestLabel, sourceBuildTestLabel), func() {
			component, err := f.AsKubeAdmin.HasController.GetComponent(symlinkComponentName, testNamespace)
			gomega.Expect(err).ShouldNot(gomega.HaveOccurred())
			gomega.Expect(f.AsKubeAdmin.HasController.WaitForComponentPipelineToBeFinished(component, "", "", "",
				f.AsKubeAdmin.TektonController, &has.RetryOptions{Retries: 0}, nil)).Should(gomega.MatchError(gomega.ContainSubstring("cloned repository contains symlink pointing outside of the cloned repository")))
		})

	})
})

func getImageWithDigest(c *framework.ControllerHub, componentName, applicationName, namespace string) (string, error) {
	var url string
	var digest string
	pipelineRun, err := c.HasController.GetComponentPipelineRun(componentName, applicationName, namespace, "")
	if err != nil {
		return "", err
	}

	for _, p := range pipelineRun.Spec.Params {
		if p.Name == "output-image" {
			url = p.Value.StringVal
		}
	}
	if url == "" {
		return "", fmt.Errorf("output-image of a component %q could not be found", componentName)
	}

	for _, r := range pipelineRun.Status.Results {
		if r.Name == "IMAGE_DIGEST" {
			digest = r.Value.StringVal
		}
	}
	if digest == "" {
		return "", fmt.Errorf("IMAGE_DIGEST for component %q could not be found", componentName)
	}
	return fmt.Sprintf("%s@%s", url, digest), nil
}

// this function takes a bundle and prefetchInput value as inputs and creates a bundle with param hermetic=true
// and then push the bundle to quay using format: quay.io/<QUAY_E2E_ORGANIZATION>/test-images:<generated_tag>
func enableHermeticBuildInPipelineBundle(customDockerBuildBundle string, pipelineBundleName constants.BuildPipelineType, prefetchInput string) (string, error) {
	var tektonObj runtime.Object
	var err error
	var newPipelineYaml []byte
	var authenticator authn.Authenticator
	// Extract docker-build pipeline as tekton object from the bundle
	if tektonObj, err = tekton.ExtractTektonObjectFromBundle(customDockerBuildBundle, "pipeline", pipelineBundleName); err != nil {
		return "", fmt.Errorf("failed to extract the Tekton Pipeline from bundle: %+v", err)
	}
	dockerPipelineObject := tektonObj.(*tektonpipeline.Pipeline)
	// Update hermetic params value to true and also update prefetch-input param value
	for i := range dockerPipelineObject.PipelineSpec().Params {
		if dockerPipelineObject.PipelineSpec().Params[i].Name == "hermetic" {
			dockerPipelineObject.PipelineSpec().Params[i].Default.StringVal = "true"
		}
		if dockerPipelineObject.PipelineSpec().Params[i].Name == "prefetch-input" {
			dockerPipelineObject.PipelineSpec().Params[i].Default.StringVal = prefetchInput
		}
	}
	if newPipelineYaml, err = yaml.Marshal(dockerPipelineObject); err != nil {
		return "", fmt.Errorf("error when marshalling a new pipeline to YAML: %v", err)
	}

	tag := fmt.Sprintf("%d-%s", time.Now().Unix(), util.GenerateRandomString(4))
	quayOrg := utils.GetEnv(constants.QUAY_E2E_ORGANIZATION_ENV, constants.DefaultQuayOrg)
	newDockerBuildPipelineImg := strings.ReplaceAll(constants.DefaultImagePushRepo, constants.DefaultQuayOrg, quayOrg)
	var newDockerBuildPipeline, _ = name.ParseReference(fmt.Sprintf("%s:pipeline-bundle-%s", newDockerBuildPipelineImg, tag))
	// Build and Push the tekton bundle
	if authenticator, err = utils.GetAuthenticatorForImageRef(newDockerBuildPipeline, os.Getenv("QUAY_TOKEN")); err != nil {
		return "", fmt.Errorf("error when getting authenticator: %v", err)
	}
	authOption := remoteimg.WithAuth(authenticator)
	if err = tekton.BuildAndPushTektonBundle(newPipelineYaml, newDockerBuildPipeline, authOption); err != nil {
		return "", fmt.Errorf("error when building/pushing a tekton pipeline bundle: %v", err)
	}
	return newDockerBuildPipeline.String(), nil
}

// this function takes a bundle and mediaType value as inputs and creates a bundle with param BUILDAH_FORMAT=<mediaType>
// and then push the bundle to quay using format: quay.io/<QUAY_E2E_ORGANIZATION>/test-images:<generated_tag>
func enableDockerMediaTypeInPipelineBundle(customDockerBuildBundle string, pipelineBundleName constants.BuildPipelineType, mediaType string) (string, error) {
	var tektonObj runtime.Object
	var err error
	var newPipelineYaml []byte
	var authenticator authn.Authenticator
	// Extract docker-build pipeline as tekton object from the bundle
	if tektonObj, err = tekton.ExtractTektonObjectFromBundle(customDockerBuildBundle, "pipeline", pipelineBundleName); err != nil {
		return "", fmt.Errorf("failed to extract the Tekton Pipeline from bundle: %+v", err)
	}
	dockerPipelineObject := tektonObj.(*tektonpipeline.Pipeline)
	// Update BUILDAH_FORMAT params value to <mediaType> (received as a function input) only for the required tasks
	for i := range dockerPipelineObject.PipelineSpec().Tasks {
		t := &dockerPipelineObject.PipelineSpec().Tasks[i]
		if t.Name == "build-container" || t.Name == "build-image-index" || t.Name == "sast-coverity-check" || t.Name == "build-images" {
			exist := false
			for param_idx := range t.Params {
				param := &t.Params[param_idx]
				if param.Name == "BUILDAH_FORMAT" {
					param.Value = *tektonpipeline.NewStructuredValues(mediaType)
					exist = true
					break
				}
			}
			if !exist {
				// param wasn't updated, add it as new param
				t.Params = append(t.Params, tektonpipeline.Param{Name: "BUILDAH_FORMAT", Value: *tektonpipeline.NewStructuredValues(mediaType)})
			}
		}
	}
	if newPipelineYaml, err = yaml.Marshal(dockerPipelineObject); err != nil {
		return "", fmt.Errorf("error when marshalling a new pipeline to YAML: %v", err)
	}

	tag := fmt.Sprintf("%d-%s", time.Now().Unix(), util.GenerateRandomString(4))
	quayOrg := utils.GetEnv(constants.QUAY_E2E_ORGANIZATION_ENV, constants.DefaultQuayOrg)
	newDockerBuildPipelineImg := strings.ReplaceAll(constants.DefaultImagePushRepo, constants.DefaultQuayOrg, quayOrg)
	var newDockerBuildPipeline, _ = name.ParseReference(fmt.Sprintf("%s:pipeline-bundle-%s", newDockerBuildPipelineImg, tag))
	// Build and Push the tekton bundle
	if authenticator, err = utils.GetAuthenticatorForImageRef(newDockerBuildPipeline, os.Getenv("QUAY_TOKEN")); err != nil {
		return "", fmt.Errorf("error when getting authenticator: %v", err)
	}
	authOption := remoteimg.WithAuth(authenticator)
	if err = tekton.BuildAndPushTektonBundle(newPipelineYaml, newDockerBuildPipeline, authOption); err != nil {
		return "", fmt.Errorf("error when building/pushing a tekton pipeline bundle: %v", err)
	}
	return newDockerBuildPipeline.String(), nil

}

// this function takes a bundle and additonalTags string slice as inputs
// and creates a bundle with adding ADDITIONAL_TAGS params in the apply-tags task
// and then push the bundle to quay using format: quay.io/<QUAY_E2E_ORGANIZATION>/test-images:<generated_tag>
func applyAdditionalTagsInPipelineBundle(customDockerBuildBundle string, pipelineBundleName constants.BuildPipelineType, additionalTags []string) (string, error) {
	var tektonObj runtime.Object
	var err error
	var newPipelineYaml []byte
	var authenticator authn.Authenticator
	// Extract docker-build pipeline as tekton object from the bundle
	if tektonObj, err = tekton.ExtractTektonObjectFromBundle(customDockerBuildBundle, "pipeline", pipelineBundleName); err != nil {
		return "", fmt.Errorf("failed to extract the Tekton Pipeline from bundle: %+v", err)
	}
	dockerPipelineObject := tektonObj.(*tektonpipeline.Pipeline)
	// Update ADDITIONAL_TAGS params arrays with additionalTags in apply-tags task
	for i := range dockerPipelineObject.PipelineSpec().Tasks {
		t := &dockerPipelineObject.PipelineSpec().Tasks[i]
		if t.Name == "apply-tags" {
			t.Params = append(t.Params, tektonpipeline.Param{Name: "ADDITIONAL_TAGS", Value: *tektonpipeline.NewStructuredValues(additionalTags[0], additionalTags[1:]...)})
		}
	}

	if newPipelineYaml, err = yaml.Marshal(dockerPipelineObject); err != nil {
		return "", fmt.Errorf("error when marshalling a new pipeline to YAML: %v", err)
	}

	tag := fmt.Sprintf("%d-%s", time.Now().Unix(), util.GenerateRandomString(4))
	quayOrg := utils.GetEnv(constants.QUAY_E2E_ORGANIZATION_ENV, constants.DefaultQuayOrg)
	newDockerBuildPipelineImg := strings.ReplaceAll(constants.DefaultImagePushRepo, constants.DefaultQuayOrg, quayOrg)
	var newDockerBuildPipeline, _ = name.ParseReference(fmt.Sprintf("%s:pipeline-bundle-%s", newDockerBuildPipelineImg, tag))
	// Build and Push the tekton bundle
	if authenticator, err = utils.GetAuthenticatorForImageRef(newDockerBuildPipeline, os.Getenv("QUAY_TOKEN")); err != nil {
		return "", fmt.Errorf("error when getting authenticator: %v", err)
	}
	authOption := remoteimg.WithAuth(authenticator)
	if err = tekton.BuildAndPushTektonBundle(newPipelineYaml, newDockerBuildPipeline, authOption); err != nil {
		return "", fmt.Errorf("error when building/pushing a tekton pipeline bundle: %v", err)
	}
	return newDockerBuildPipeline.String(), nil
}

// this function takes a bundle and workindDirMount string as inputs
// and creates a bundle with added WORKINDDIR_MOUNT param in the buildah task
// and then pushes the bundle to quay using format: quay.io/<QUAY_E2E_ORGANIZATION>/test-images:<generated_tag>
func addWorkingDirMountInPipelineBundle(customDockerBuildBundle string, pipelineBundleName constants.BuildPipelineType, workingDirMount string) (string, error) {
	var tektonObj runtime.Object
	var err error
	var newPipelineYaml []byte
	var authenticator authn.Authenticator
	// Extract docker-build pipeline as tekton object from the bundle
	if tektonObj, err = tekton.ExtractTektonObjectFromBundle(customDockerBuildBundle, "pipeline", pipelineBundleName); err != nil {
		return "", fmt.Errorf("failed to extract the Tekton Pipeline from bundle: %+v", err)
	}
	dockerPipelineObject := tektonObj.(*tektonpipeline.Pipeline)
	// Update WORKINGDIR_MOUNT param value for build-container task
	for i := range dockerPipelineObject.PipelineSpec().Tasks {
		t := &dockerPipelineObject.PipelineSpec().Tasks[i]
		if t.Name == "build-container" {
			t.Params = append(t.Params, tektonpipeline.Param{Name: "WORKINGDIR_MOUNT", Value: tektonpipeline.ParamValue{
				Type:      tektonpipeline.ParamTypeString,
				StringVal: workingDirMount,
			}})
		}
	}
	if newPipelineYaml, err = yaml.Marshal(dockerPipelineObject); err != nil {
		return "", fmt.Errorf("error when marshalling a new pipeline to YAML: %v", err)
	}

	tag := fmt.Sprintf("%d-%s", time.Now().Unix(), util.GenerateRandomString(4))
	quayOrg := utils.GetEnv(constants.QUAY_E2E_ORGANIZATION_ENV, constants.DefaultQuayOrg)
	newDockerBuildPipelineImg := strings.ReplaceAll(constants.DefaultImagePushRepo, constants.DefaultQuayOrg, quayOrg)
	var newDockerBuildPipeline, _ = name.ParseReference(fmt.Sprintf("%s:pipeline-bundle-%s", newDockerBuildPipelineImg, tag))
	// Build and Push the tekton bundle
	if authenticator, err = utils.GetAuthenticatorForImageRef(newDockerBuildPipeline, os.Getenv("QUAY_TOKEN")); err != nil {
		return "", fmt.Errorf("error when getting authenticator: %v", err)
	}
	authOption := remoteimg.WithAuth(authenticator)
	if err = tekton.BuildAndPushTektonBundle(newPipelineYaml, newDockerBuildPipeline, authOption); err != nil {
		return "", fmt.Errorf("error when building/pushing a tekton pipeline bundle: %v", err)
	}
	return newDockerBuildPipeline.String(), nil

}

func ensureOriginalDockerfileIsPushed(hub *framework.ControllerHub, pr *tektonpipeline.PipelineRun) {
	binaryImage := build.GetBinaryImage(pr)
	gomega.Expect(binaryImage).ShouldNot(gomega.BeEmpty())

	binaryImageRef, err := reference.Parse(binaryImage)
	gomega.Expect(err).Should(gomega.Succeed())

	tagInfo, err := build.GetImageTag(binaryImageRef.Namespace, binaryImageRef.Name, binaryImageRef.Tag)
	gomega.Expect(err).Should(gomega.Succeed())

	dockerfileImageTag := fmt.Sprintf("%s.dockerfile", strings.Replace(tagInfo.ManifestDigest, ":", "-", 1))

	dockerfileImage := reference.DockerImageReference{
		Registry:  binaryImageRef.Registry,
		Namespace: binaryImageRef.Namespace,
		Name:      binaryImageRef.Name,
		Tag:       dockerfileImageTag,
	}.String()
	exists, err := build.DoesTagExistsInQuay(dockerfileImage)
	gomega.Expect(err).Should(gomega.Succeed())
	gomega.Expect(exists).Should(gomega.BeTrue(), fmt.Sprintf("image doesn't exist: %s", dockerfileImage))

	// Ensure the original Dockerfile used for build was pushed
	c := hub.CommonController.KubeRest()
	originDockerfileContent, err := build.ReadDockerfileUsedForBuild(c, hub.TektonController, pr)
	gomega.Expect(err).Should(gomega.Succeed())

	storePath, err := oras.PullArtifacts(dockerfileImage)
	gomega.Expect(err).Should(gomega.Succeed())
	entries, err := os.ReadDir(storePath)
	gomega.Expect(err).Should(gomega.Succeed())
	for _, entry := range entries {
		if entry.Type().IsRegular() && entry.Name() == "Dockerfile" {
			content, err := os.ReadFile(filepath.Join(storePath, entry.Name()))
			gomega.Expect(err).Should(gomega.Succeed())
			gomega.Expect(string(content)).Should(gomega.Equal(string(originDockerfileContent)))
			return
		}
	}

	ginkgo.Fail(fmt.Sprintf("Dockerfile is not found from the pulled artifacts for %s", dockerfileImage))
}
