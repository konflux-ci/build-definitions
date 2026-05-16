package build

import (
	"fmt"
	"strings"

	"github.com/konflux-ci/e2e-tests/pkg/clients/tekton"
	"github.com/konflux-ci/e2e-tests/pkg/framework"
	"github.com/konflux-ci/e2e-tests/pkg/utils/build"
	ginkgo "github.com/onsi/ginkgo/v2"
	gomega "github.com/onsi/gomega"
	"github.com/openshift/library-go/pkg/image/reference"
	pipeline "github.com/tektoncd/pipeline/pkg/apis/pipeline/v1"
	"sigs.k8s.io/controller-runtime/pkg/client"
)

func parseDockerfileUsedForBuild(
	c client.Client, tektonController *tekton.TektonController, pr *pipeline.PipelineRun,
) *build.Dockerfile {
	dockerfileContent, err := build.ReadDockerfileUsedForBuild(c, tektonController, pr)
	gomega.Expect(err).ShouldNot(gomega.HaveOccurred())

	parsedDockerfile, err := build.ParseDockerfile(dockerfileContent)
	gomega.Expect(err).ShouldNot(gomega.HaveOccurred())

	return parsedDockerfile
}

// CheckParentSources checks the sources coming from parent image are all included in the built source image.
// This check is applied to every build for which source build is enabled, then the several prerequisites
// for including parent sources are handled as well.
func CheckParentSources(c client.Client, tektonController *tekton.TektonController, pr *pipeline.PipelineRun, gitUrl string) {
	buildResult, err := build.ReadSourceBuildResult(c, tektonController, pr)
	gomega.Expect(err).ShouldNot(gomega.HaveOccurred())

	var baseImagesDigests []string
	if IsDockerBuildGitURL(gitUrl) {
		parsedDockerfile := parseDockerfileUsedForBuild(c, tektonController, pr)
		if parsedDockerfile.IsBuildFromScratch() {
			gomega.Expect(buildResult.BaseImageSourceIncluded).Should(gomega.BeFalse())
			return
		}
		baseImagesDigests, err = parsedDockerfile.ConvertParentImagesToBuildahOutputForm()
		gomega.Expect(err).ShouldNot(gomega.HaveOccurred())
	} else {
		ginkgo.Fail("CheckParentSources only works for docker-build pipelines")
	}

	lastBaseImage := baseImagesDigests[len(baseImagesDigests)-1]
	// Remove <none> part if there is. Otherwise, reference.Parse will fail.
	imageWithoutTag := strings.Replace(lastBaseImage, ":<none>", "", 1)
	ref, err := reference.Parse(imageWithoutTag)
	gomega.Expect(err).ShouldNot(gomega.HaveOccurred(), fmt.Sprintf("can't parse image reference %s", imageWithoutTag))
	imageWithoutTag = ref.Exact() // drop the tag

	allowed, err := build.IsImagePulledFromAllowedRegistry(imageWithoutTag)
	gomega.Expect(err).ShouldNot(gomega.HaveOccurred())

	var parentSourceImage string

	if allowed {
		parentSourceImage, err = build.ResolveSourceImageByVersionRelease(imageWithoutTag)
	} else {
		parentSourceImage, err = build.ResolveKonfluxSourceImage(imageWithoutTag)
	}
	gomega.Expect(err).ShouldNot(gomega.HaveOccurred())

	allIncluded, err := build.AllParentSourcesIncluded(parentSourceImage, buildResult.ImageUrl)

	if err != nil {
		msg := err.Error()
		if strings.Contains(msg, "parent source image manifest") && strings.Contains(msg, "MANIFEST_UNKNOWN:") {
			return
		} else {
			ginkgo.Fail(fmt.Sprintf("failed to check parent sources: %v", err))
		}
	}

	gomega.Expect(allIncluded).Should(gomega.BeTrue())
	gomega.Expect(buildResult.BaseImageSourceIncluded).Should(gomega.BeTrue())
}

func CheckSourceImage(srcImage, gitUrl string, hub *framework.ControllerHub, pr *pipeline.PipelineRun) {
	//Check if hermetic enabled
	isHermeticBuildEnabled := build.IsHermeticBuildEnabled(pr)
	ginkgo.GinkgoWriter.Printf("HERMETIC STATUS: %v\n", isHermeticBuildEnabled)

	//Get prefetch input value
	prefetchInputValue := build.GetPrefetchValue(pr)
	ginkgo.GinkgoWriter.Printf("PRE-FETCH VALUE: %v\n", prefetchInputValue)

	filesExists, err := build.IsSourceFilesExistsInSourceImage(
		srcImage, gitUrl, isHermeticBuildEnabled, prefetchInputValue)
	gomega.Expect(err).ShouldNot(gomega.HaveOccurred())
	gomega.Expect(filesExists).To(gomega.BeTrue())

	c := hub.CommonController.KubeRest()
	CheckParentSources(c, hub.TektonController, pr, gitUrl)
}
