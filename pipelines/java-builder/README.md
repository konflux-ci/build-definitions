# "java-builder pipeline"
## Parameters
|name|description|default value|used in (taskname:taskrefversion:taskparam)|
|---|---|---|---|
|build-source-image| Build a source image.| false| |
|dockerfile| Path to the Dockerfile inside the context specified by parameter path-context| Dockerfile| |
|git-url| Source Repository URL| None| clone-repository:0.1:url|
|hermetic| Execute the build with network isolation| false| |
|image-expires-after| Image tag expiration time, time values could be something like 1h, 2d, 3w for hours, days, and weeks, respectively.| | build-container:0.1:IMAGE_EXPIRES_AFTER|
|java| Java build| false| |
|output-image| Fully Qualified Output Image| None| show-summary:0.2:image-url ; init:0.2:image-url ; build-container:0.1:IMAGE ; build-source-image:0.1:BINARY_IMAGE|
|path-context| Path to the source code of an application's component from where to build image.| .| build-container:0.1:PATH_CONTEXT|
|prefetch-input| Build dependencies to be prefetched by Cachi2| | prefetch-dependencies:0.1:input|
|rebuild| Force rebuild image| false| init:0.2:rebuild|
|revision| Revision of the Source Repository| | clone-repository:0.1:revision|
|skip-checks| Skip checks against built image| false| init:0.2:skip-checks|
## Available params from tasks
### clair-scan:0.1 task parameters
|name|description|default value|already set by|
|---|---|---|---|
|docker-auth| unused, should be removed in next task version.| | |
|image-digest| Image digest to scan.| None| '$(tasks.build-container.results.IMAGE_DIGEST)'|
|image-url| Image URL.| None| '$(tasks.build-container.results.IMAGE_URL)'|
### clamav-scan:0.1 task parameters
|name|description|default value|already set by|
|---|---|---|---|
|docker-auth| unused| | |
|image-digest| Image digest to scan.| None| '$(tasks.build-container.results.IMAGE_DIGEST)'|
|image-url| Image URL.| None| '$(tasks.build-container.results.IMAGE_URL)'|
### deprecated-image-check:0.4 task parameters
|name|description|default value|already set by|
|---|---|---|---|
|BASE_IMAGES_DIGESTS| Digests of base build images.| | '$(tasks.build-container.results.BASE_IMAGES_DIGESTS)'|
|IMAGE_DIGEST| Image digest.| None| '$(tasks.build-container.results.IMAGE_DIGEST)'|
|IMAGE_URL| Fully qualified image name.| None| '$(tasks.build-container.results.IMAGE_URL)'|
|POLICY_DIR| Path to directory containing Conftest policies.| /project/repository/| |
|POLICY_NAMESPACE| Namespace for Conftest policy.| required_checks| |
### ecosystem-cert-preflight-checks:0.1 task parameters
|name|description|default value|already set by|
|---|---|---|---|
|image-url| Image url to scan.| None| '$(tasks.build-container.results.IMAGE_URL)'|
### git-clone:0.1 task parameters
|name|description|default value|already set by|
|---|---|---|---|
|caTrustConfigMapKey| The name of the key in the ConfigMap that contains the CA bundle data.| ca-bundle.crt| |
|caTrustConfigMapName| The name of the ConfigMap to read CA bundle data from.| trusted-ca| |
|deleteExisting| Clean out the contents of the destination directory if it already exists before cloning.| true| |
|depth| Perform a shallow clone, fetching only the most recent N commits.| 1| |
|enableSymlinkCheck| Check symlinks in the repo. If they're pointing outside of the repo, the build will fail. | true| |
|fetchTags| Fetch all tags for the repo.| false| |
|gitInitImage| Deprecated. Has no effect. Will be removed in the future.| | |
|httpProxy| HTTP proxy server for non-SSL requests.| | |
|httpsProxy| HTTPS proxy server for SSL requests.| | |
|noProxy| Opt out of proxying HTTP/HTTPS requests.| | |
|refspec| Refspec to fetch before checking out revision.| | |
|revision| Revision to checkout. (branch, tag, sha, ref, etc...)| | '$(params.revision)'|
|sparseCheckoutDirectories| Define the directory patterns to match or exclude when performing a sparse checkout.| | |
|sslVerify| Set the `http.sslVerify` global git config. Setting this to `false` is not advised unless you are sure that you trust your git remote.| true| |
|subdirectory| Subdirectory inside the `output` Workspace to clone the repo into.| source| |
|submodules| Initialize and fetch git submodules.| true| |
|url| Repository URL to clone from.| None| '$(params.git-url)'|
|userHome| Absolute path to the user's home directory. Set this explicitly if you are running the image as a non-root user. | /tekton/home| |
|verbose| Log the commands that are executed during `git-clone`'s operation.| false| |
### init:0.2 task parameters
|name|description|default value|already set by|
|---|---|---|---|
|image-url| Image URL for build by PipelineRun| None| '$(params.output-image)'|
|rebuild| Rebuild the image if exists| false| '$(params.rebuild)'|
|skip-checks| Skip checks against built image| false| '$(params.skip-checks)'|
### prefetch-dependencies:0.1 task parameters
|name|description|default value|already set by|
|---|---|---|---|
|caTrustConfigMapKey| The name of the key in the ConfigMap that contains the CA bundle data.| ca-bundle.crt| |
|caTrustConfigMapName| The name of the ConfigMap to read CA bundle data from.| trusted-ca| |
|dev-package-managers| Enable in-development package managers. WARNING: the behavior may change at any time without notice. Use at your own risk. | false| |
|input| Configures project packages that will have their dependencies prefetched.| None| '$(params.prefetch-input)'|
|log-level| Set cachi2 log level (debug, info, warning, error)| info| |
### s2i-java:0.1 task parameters
|name|description|default value|already set by|
|---|---|---|---|
|BASE_IMAGE| Java builder image| registry.access.redhat.com/ubi9/openjdk-17:1.13-10.1669632202| |
|BUILDER_IMAGE| Deprecated. Has no effect. Will be removed in the future.| | |
|COMMIT_SHA| The image is built from this commit.| | '$(tasks.clone-repository.results.commit)'|
|DOCKER_AUTH| unused, should be removed in next task version| | |
|IMAGE| Location of the repo where image has to be pushed| None| '$(params.output-image)'|
|IMAGE_EXPIRES_AFTER| Delete image tag after specified time. Empty means to keep the image tag. Time values could be something like 1h, 2d, 3w for hours, days, and weeks, respectively.| | '$(params.image-expires-after)'|
|PATH_CONTEXT| The location of the path to run s2i from| .| '$(params.path-context)'|
|TLSVERIFY| Verify the TLS on the registry endpoint (for push/pull to a non-TLS registry)| true| |
### sast-snyk-check:0.1 task parameters
|name|description|default value|already set by|
|---|---|---|---|
|ARGS| Append arguments.| --all-projects --exclude=test*,vendor,deps| |
|SNYK_SECRET| Name of secret which contains Snyk token.| snyk-secret| |
### sbom-json-check:0.1 task parameters
|name|description|default value|already set by|
|---|---|---|---|
|IMAGE_DIGEST| Image digest.| None| '$(tasks.build-container.results.IMAGE_DIGEST)'|
|IMAGE_URL| Fully qualified image name to verify.| None| '$(tasks.build-container.results.IMAGE_URL)'|
### show-sbom:0.1 task parameters
|name|description|default value|already set by|
|---|---|---|---|
|IMAGE_URL| Fully qualified image name to show SBOM for.| None| '$(tasks.build-container.results.IMAGE_URL)'|
|PLATFORM| Specific architecture to display the SBOM for. An example arch would be "linux/amd64". If IMAGE_URL refers to a multi-arch image and this parameter is empty, the task will default to use "linux/amd64".| linux/amd64| |
### source-build:0.1 task parameters
|name|description|default value|already set by|
|---|---|---|---|
|BASE_IMAGES| Base images used to build the binary image. Each image per line in the same order of FROM instructions specified in a multistage Dockerfile. Default to an empty string, which means to skip handling a base image.| | '$(tasks.build-container.results.BASE_IMAGES_DIGESTS)'|
|BINARY_IMAGE| Binary image name from which to generate the source image name.| None| '$(params.output-image)'|
### summary:0.2 task parameters
|name|description|default value|already set by|
|---|---|---|---|
|build-task-status| State of build task in pipelineRun| Succeeded| '$(tasks.build-container.status)'|
|git-url| Git URL| None| '$(tasks.clone-repository.results.url)?rev=$(tasks.clone-repository.results.commit)'|
|image-url| Image URL| None| '$(params.output-image)'|
|pipelinerun-name| pipeline-run to annotate| None| '$(context.pipelineRun.name)'|

## Results
|name|description|value|
|---|---|---|
|CHAINS-GIT_COMMIT| |$(tasks.clone-repository.results.commit)|
|CHAINS-GIT_URL| |$(tasks.clone-repository.results.url)|
|IMAGE_DIGEST| |$(tasks.build-container.results.IMAGE_DIGEST)|
|IMAGE_URL| |$(tasks.build-container.results.IMAGE_URL)|
|JAVA_COMMUNITY_DEPENDENCIES| |$(tasks.build-container.results.JAVA_COMMUNITY_DEPENDENCIES)|
## Available results from tasks
### clair-scan:0.1 task results
|name|description|used in params (taskname:taskrefversion:taskparam)
|---|---|---|
|CLAIR_SCAN_RESULT| Clair scan result.| |
|IMAGES_PROCESSED| Images processed in the task.| |
|TEST_OUTPUT| Tekton task test output.| |
### clamav-scan:0.1 task results
|name|description|used in params (taskname:taskrefversion:taskparam)
|---|---|---|
|IMAGES_PROCESSED| Images processed in the task.| |
|TEST_OUTPUT| Tekton task test output.| |
### deprecated-image-check:0.4 task results
|name|description|used in params (taskname:taskrefversion:taskparam)
|---|---|---|
|TEST_OUTPUT| Tekton task test output.| |
### ecosystem-cert-preflight-checks:0.1 task results
|name|description|used in params (taskname:taskrefversion:taskparam)
|---|---|---|
|TEST_OUTPUT| Preflight pass or fail outcome.| |
### git-clone:0.1 task results
|name|description|used in params (taskname:taskrefversion:taskparam)
|---|---|---|
|commit| The precise commit SHA that was fetched by this Task.| build-container:0.1:COMMIT_SHA|
|url| The precise URL that was fetched by this Task.| show-summary:0.2:git-url|
### init:0.2 task results
|name|description|used in params (taskname:taskrefversion:taskparam)
|---|---|---|
|build| Defines if the image in param image-url should be built| |
### s2i-java:0.1 task results
|name|description|used in params (taskname:taskrefversion:taskparam)
|---|---|---|
|BASE_IMAGES_DIGESTS| Digests of the base images used for build| build-source-image:0.1:BASE_IMAGES ; deprecated-base-image-check:0.4:BASE_IMAGES_DIGESTS|
|IMAGE_DIGEST| Digest of the image just built| deprecated-base-image-check:0.4:IMAGE_DIGEST ; clair-scan:0.1:image-digest ; clamav-scan:0.1:image-digest ; sbom-json-check:0.1:IMAGE_DIGEST|
|IMAGE_URL| Image repository where the built image was pushed| show-sbom:0.1:IMAGE_URL ; deprecated-base-image-check:0.4:IMAGE_URL ; clair-scan:0.1:image-url ; ecosystem-cert-preflight-checks:0.1:image-url ; clamav-scan:0.1:image-url ; sbom-json-check:0.1:IMAGE_URL|
|JAVA_COMMUNITY_DEPENDENCIES| The Java dependencies that came from community sources such as Maven central.| |
|SBOM_JAVA_COMPONENTS_COUNT| The counting of Java components by publisher in JSON format| |
### sast-snyk-check:0.1 task results
|name|description|used in params (taskname:taskrefversion:taskparam)
|---|---|---|
|TEST_OUTPUT| Tekton task test output.| |
### sbom-json-check:0.1 task results
|name|description|used in params (taskname:taskrefversion:taskparam)
|---|---|---|
|IMAGES_PROCESSED| Images processed in the task.| |
|TEST_OUTPUT| Tekton task test output.| |
### source-build:0.1 task results
|name|description|used in params (taskname:taskrefversion:taskparam)
|---|---|---|
|BUILD_RESULT| Build result.| |
|SOURCE_IMAGE_DIGEST| The source image digest.| |
|SOURCE_IMAGE_URL| The source image url.| |

## Workspaces
|name|description|optional|used in tasks
|---|---|---|---|
|git-auth| |True| clone-repository:0.1:basic-auth ; prefetch-dependencies:0.1:git-basic-auth|
|workspace| |False| show-summary:0.2:workspace ; clone-repository:0.1:output ; prefetch-dependencies:0.1:source ; build-container:0.1:source ; build-source-image:0.1:workspace ; sast-snyk-check:0.1:workspace|
## Available workspaces from tasks
### git-clone:0.1 task workspaces
|name|description|optional|workspace from pipeline
|---|---|---|---|
|basic-auth| A Workspace containing a .gitconfig and .git-credentials file or username and password. These will be copied to the user's home before any git commands are run. Any other files in this Workspace are ignored. It is strongly recommended to use ssh-directory over basic-auth whenever possible and to bind a Secret to this Workspace over other volume types. | True| git-auth|
|output| The git repo will be cloned onto the volume backing this Workspace.| False| workspace|
|ssh-directory| A .ssh directory with private key, known_hosts, config, etc. Copied to the user's home before git commands are executed. Used to authenticate with the git remote when performing the clone. Binding a Secret to this Workspace is strongly recommended over other volume types. | True| |
### prefetch-dependencies:0.1 task workspaces
|name|description|optional|workspace from pipeline
|---|---|---|---|
|git-basic-auth| A Workspace containing a .gitconfig and .git-credentials file or username and password. These will be copied to the user's home before any cachi2 commands are run. Any other files in this Workspace are ignored. It is strongly recommended to bind a Secret to this Workspace over other volume types. | True| git-auth|
|source| Workspace with the source code, cachi2 artifacts will be stored on the workspace as well| False| workspace|
### s2i-java:0.1 task workspaces
|name|description|optional|workspace from pipeline
|---|---|---|---|
|source| Workspace containing the source code to build.| False| workspace|
### sast-snyk-check:0.1 task workspaces
|name|description|optional|workspace from pipeline
|---|---|---|---|
|workspace| | False| workspace|
### source-build:0.1 task workspaces
|name|description|optional|workspace from pipeline
|---|---|---|---|
|workspace| The workspace where source code is included.| False| workspace|
### summary:0.2 task workspaces
|name|description|optional|workspace from pipeline
|---|---|---|---|
|workspace| The workspace where source code is included.| True| workspace|
