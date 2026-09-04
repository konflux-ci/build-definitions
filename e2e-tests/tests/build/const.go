package build

import (
	"strings"

	"github.com/konflux-ci/e2e-tests/pkg/utils"
)

const (
	COMPONENT_REPO_URLS_ENV string = "COMPONENT_REPO_URLS"
	SCENARIOS_ENV           string = "SCENARIOS"

	containerImageSource       = "quay.io/redhat-appstudio-qe/busybox-loop@sha256:f698f1f2cf641fe9176d2a277c9052d872f6b1c39e56248a1dd259b96281dda9"
	dummyPipelineBundleRef     = "quay.io/redhat-appstudio-qe/dummy-pipeline-bundle@sha256:9805fc3f309af8f838622e49d3e7705d8364eb5c8287043d5725f3ef12232f24"
	buildTemplatesTestLabel    = "build-templates-e2e"
	buildTemplatesKcpTestLabel = "build-templates-kcp-e2e"
	sourceBuildTestLabel       = "source-build-e2e"

	fbcComponentGitHubURL = "https://github.com/konflux-qe-bd/fbc-sample-repo"
)

var (
	componentUrls        = strings.Split(utils.GetEnv(COMPONENT_REPO_URLS_ENV, fbcComponentGitHubURL), ",")
	basicScenarioUrls    = []string{fbcComponentGitHubURL}
	hermeticScenarioUrls = []string{}
)
