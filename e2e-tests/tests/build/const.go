package build

import (
	"fmt"
	"strings"

	"github.com/konflux-ci/e2e-tests/pkg/constants"
	"github.com/konflux-ci/e2e-tests/pkg/utils"
)

const (
	COMPONENT_REPO_URLS_ENV string = "COMPONENT_REPO_URLS"
	SCENARIOS_ENV           string = "SCENARIOS"

	containerImageSource             = "quay.io/redhat-appstudio-qe/busybox-loop@sha256:f698f1f2cf641fe9176d2a277c9052d872f6b1c39e56248a1dd259b96281dda9"
	gitRepoContainsSymlinkBranchName = "symlink"
	symlinkBranchRevision            = "27ecfca9c9dad35e4f07ebbcd706f31cb7ce849f"
	dummyPipelineBundleRef           = "quay.io/redhat-appstudio-qe/dummy-pipeline-bundle@sha256:9805fc3f309af8f838622e49d3e7705d8364eb5c8287043d5725f3ef12232f24"
	buildTemplatesTestLabel          = "build-templates-e2e"
	buildTemplatesKcpTestLabel       = "build-templates-kcp-e2e"
	sourceBuildTestLabel             = "source-build-e2e"

	pythonComponentRepoName = "devfile-sample-python-basic"

	githubUrlFormat = "https://github.com/%s/%s"
)

var (
	additionalTags           = []string{"test-tag1", "test-tag2"}
	componentUrls            = strings.Split(utils.GetEnv(COMPONENT_REPO_URLS_ENV, pythonComponentGitHubURL), ",")
	githubOrg                = utils.GetEnv(constants.GITHUB_E2E_ORGANIZATION_ENV, "redhat-appstudio-qe")
	pythonComponentGitHubURL = fmt.Sprintf(githubUrlFormat, githubOrg, pythonComponentRepoName)
	basicScenarioUrls        = []string{"https://github.com/konflux-qe-bd/devfile-sample-python-basic", "https://github.com/konflux-qe-bd/devfile-sample-python-basic-clone", "https://github.com/konflux-qe-bd/multiarch-sample-repo", "https://github.com/konflux-qe-bd/multiarch-sample-repo-clone", "https://github.com/konflux-qe-bd/fbc-sample-repo", "https://github.com/konflux-qe-bd/docker-file-from-scratch", "https://github.com/konflux-qe-bd/oci-archive-test"}
	hermeticScenarioUrls     = []string{"https://github.com/konflux-qe-bd/retrodep", "https://github.com/konflux-qe-bd/pip-e2e-test", "https://github.com/konflux-qe-bd/ruby-bundler-sample-app", "https://github.com/konflux-qe-bd/rust-cargo-sample-app", "https://github.com/konflux-qe-bd/nodejs-npm-sample-repo", "https://github.com/konflux-qe-bd/nodejs-yarn-sample-app", "https://github.com/konflux-qe-bd/nodejs-yarn-modern-sample-app", "https://github.com/konflux-qe-bd/rpm-sample-app", "https://github.com/konflux-qe-bd/generic-fetcher-sample-app"}
)
