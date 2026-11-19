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
)

var (
	componentUrls        = filterEmpty(strings.Split(utils.GetEnv(COMPONENT_REPO_URLS_ENV, ""), ","))
	basicScenarioUrls    = []string{}
	hermeticScenarioUrls = []string{}
)

// filterEmpty removes empty entries that result from splitting an empty or
// trailing-comma string, so an unset COMPONENT_REPO_URLS yields no scenarios.
func filterEmpty(in []string) []string {
	out := make([]string, 0, len(in))
	for _, s := range in {
		if strings.TrimSpace(s) != "" {
			out = append(out, s)
		}
	}
	return out
}
