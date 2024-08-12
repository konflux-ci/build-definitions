# "fbc-builder pipeline"
## Parameters
|name|description|default value|used in (taskname:taskrefversion:taskparam)|
|---|---|---|---|
|build-source-image| Build a source image.| false| |
|dockerfile| Path to the Dockerfile inside the context specified by parameter path-context| Dockerfile| build-container:0.1:DOCKERFILE ; push-dockerfile:0.1:DOCKERFILE|
|git-url| Source Repository URL| None| clone-repository:0.1:url|
|hermetic| Execute the build with network isolation| false| |
|image-expires-after| Image tag expiration time, time values could be something like 1h, 2d, 3w for hours, days, and weeks, respectively.| | build-container:0.1:IMAGE_EXPIRES_AFTER|
|java| Java build| false| |
|output-image| Fully Qualified Output Image| None| show-summary:0.2:image-url ; init:0.2:image-url ; build-container:0.1:IMAGE|
|path-context| Path to the source code of an application's component from where to build image.| .| build-container:0.1:CONTEXT ; push-dockerfile:0.1:CONTEXT|
|prefetch-input| Build dependencies to be prefetched by Cachi2| | |
|rebuild| Force rebuild image| false| init:0.2:rebuild|
|revision| Revision of the Source Repository| | clone-repository:0.1:revision|
|skip-checks| Skip checks against built image| false| init:0.2:skip-checks|
## Available params from tasks
### apply-tags:0.1 task parameters
|name|description|default value|already set by|
|---|---|---|---|
|ADDITIONAL_TAGS| Additional tags that will be applied to the image in the registry.| []| |
|IMAGE| Reference of image that was pushed to registry in the buildah task.| None| '$(tasks.build-container.results.IMAGE_URL)'|
### buildah:0.1 task parameters
|name|description|default value|already set by|
|---|---|---|---|
|ACTIVATION_KEY| Name of secret which contains subscription activation key| activation-key| |
|ADDITIONAL_SECRET| Name of a secret which will be made available to the build with 'buildah build --secret' at /run/secrets/$ADDITIONAL_SECRET| does-not-exist| |
|ADD_CAPABILITIES| Comma separated list of extra capabilities to add when running 'buildah build'| | |
|BUILDER_IMAGE| Deprecated. Has no effect. Will be removed in the future.| | |
|BUILD_ARGS| Array of --build-arg values ("arg=value" strings)| []| |
|BUILD_ARGS_FILE| Path to a file with build arguments, see https://www.mankier.com/1/buildah-build#--build-arg-file| | |
|COMMIT_SHA| The image is built from this commit.| | '$(tasks.clone-repository.results.commit)'|
|CONTEXT| Path to the directory to use as context.| .| '$(params.path-context)'|
|DOCKERFILE| Path to the Dockerfile to build.| ./Dockerfile| '$(params.dockerfile)'|
|DOCKER_AUTH| unused, should be removed in next task version| | |
|ENTITLEMENT_SECRET| Name of secret which contains the entitlement certificates| etc-pki-entitlement| |
|HERMETIC| Determines if build will be executed without network access.| false| 'true'|
|IMAGE| Reference of the image buildah will produce.| None| '$(params.output-image)'|
|IMAGE_EXPIRES_AFTER| Delete image tag after specified time. Empty means to keep the image tag. Time values could be something like 1h, 2d, 3w for hours, days, and weeks, respectively.| | '$(params.image-expires-after)'|
|PREFETCH_INPUT| In case it is not empty, the prefetched content should be made available to the build.| | |
|SKIP_UNUSED_STAGES| Whether to skip stages in Containerfile that seem unused by subsequent stages| true| |
|SQUASH| Squash all new and previous layers added as a part of this build, as per --squash| false| |
|STORAGE_DRIVER| Storage driver to configure for buildah| vfs| |
|TARGET_STAGE| Target stage in Dockerfile to build. If not specified, the Dockerfile is processed entirely to (and including) its last stage.| | |
|TLSVERIFY| Verify the TLS on the registry endpoint (for push/pull to a non-TLS registry)| true| |
|YUM_REPOS_D_FETCHED| Path in source workspace where dynamically-fetched repos are present| fetched.repos.d| |
|YUM_REPOS_D_SRC| Path in the git repository in which yum repository files are stored| repos.d| |
|YUM_REPOS_D_TARGET| Target path on the container in which yum repository files should be made available| /etc/yum.repos.d| |
|caTrustConfigMapKey| The name of the key in the ConfigMap that contains the CA bundle data.| ca-bundle.crt| |
|caTrustConfigMapName| The name of the ConfigMap to read CA bundle data from.| trusted-ca| |
### deprecated-image-check:0.4 task parameters
|name|description|default value|already set by|
|---|---|---|---|
|BASE_IMAGES_DIGESTS| Digests of base build images.| | |
|IMAGE_DIGEST| Image digest.| None| '$(tasks.build-container.results.IMAGE_DIGEST)'|
|IMAGE_URL| Fully qualified image name.| None| '$(tasks.build-container.results.IMAGE_URL)'|
|POLICY_DIR| Path to directory containing Conftest policies.| /project/repository/| |
|POLICY_NAMESPACE| Namespace for Conftest policy.| required_checks| |
### fbc-validation:0.1 task parameters
|name|description|default value|already set by|
|---|---|---|---|
|BASE_IMAGE| Fully qualified base image name.| None| '$(tasks.inspect-image.results.BASE_IMAGE)'|
|IMAGE_DIGEST| Image digest.| None| '$(tasks.build-container.results.IMAGE_DIGEST)'|
|IMAGE_URL| Fully qualified image name.| None| '$(tasks.build-container.results.IMAGE_URL)'|
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
### inspect-image:0.1 task parameters
|name|description|default value|already set by|
|---|---|---|---|
|DOCKER_AUTH| unused, should be removed in next task version| | |
|IMAGE_DIGEST| Image digest.| None| '$(tasks.build-container.results.IMAGE_DIGEST)'|
|IMAGE_URL| Fully qualified image name.| None| '$(tasks.build-container.results.IMAGE_URL)'|
### push-dockerfile:0.1 task parameters
|name|description|default value|already set by|
|---|---|---|---|
|ARTIFACT_TYPE| Artifact type of the Dockerfile image.| application/vnd.konflux.dockerfile| |
|CONTEXT| Path to the directory to use as context.| .| '$(params.path-context)'|
|DOCKERFILE| Path to the Dockerfile.| ./Dockerfile| '$(params.dockerfile)'|
|IMAGE| The built binary image. The Dockerfile is pushed to the same image repository alongside.| None| '$(tasks.build-container.results.IMAGE_URL)'|
|IMAGE_DIGEST| The built binary image digest, which is used to construct the tag of Dockerfile image.| None| '$(tasks.build-container.results.IMAGE_DIGEST)'|
|TAG_SUFFIX| Suffix of the Dockerfile image tag.| .dockerfile| |
### sbom-json-check:0.1 task parameters
|name|description|default value|already set by|
|---|---|---|---|
|CA_TRUST_CONFIG_MAP_KEY| The name of the key in the ConfigMap that contains the CA bundle data.| ca-bundle.crt| |
|CA_TRUST_CONFIG_MAP_NAME| The name of the ConfigMap to read CA bundle data from.| trusted-ca| |
|IMAGE_DIGEST| Image digest.| None| '$(tasks.build-container.results.IMAGE_DIGEST)'|
|IMAGE_URL| Fully qualified image name to verify.| None| '$(tasks.build-container.results.IMAGE_URL)'|
### show-sbom:0.1 task parameters
|name|description|default value|already set by|
|---|---|---|---|
|CA_TRUST_CONFIG_MAP_KEY| The name of the key in the ConfigMap that contains the CA bundle data.| ca-bundle.crt| |
|CA_TRUST_CONFIG_MAP_NAME| The name of the ConfigMap to read CA bundle data from.| trusted-ca| |
|IMAGE_URL| Fully qualified image name to show SBOM for.| None| '$(tasks.build-container.results.IMAGE_URL)'|
|PLATFORM| Specific architecture to display the SBOM for. An example arch would be "linux/amd64". If IMAGE_URL refers to a multi-arch image and this parameter is empty, the task will default to use "linux/amd64".| linux/amd64| |
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
## Available results from tasks
### buildah:0.1 task results
|name|description|used in params (taskname:taskrefversion:taskparam)
|---|---|---|
|BASE_IMAGES_DIGESTS| Digests of the base images used for build| |
|IMAGE_DIGEST| Digest of the image just built| deprecated-base-image-check:0.4:IMAGE_DIGEST ; sbom-json-check:0.1:IMAGE_DIGEST ; push-dockerfile:0.1:IMAGE_DIGEST ; inspect-image:0.1:IMAGE_DIGEST ; fbc-validate:0.1:IMAGE_DIGEST|
|IMAGE_URL| Image repository where the built image was pushed| show-sbom:0.1:IMAGE_URL ; deprecated-base-image-check:0.4:IMAGE_URL ; sbom-json-check:0.1:IMAGE_URL ; apply-tags:0.1:IMAGE ; push-dockerfile:0.1:IMAGE ; inspect-image:0.1:IMAGE_URL ; fbc-validate:0.1:IMAGE_URL|
|JAVA_COMMUNITY_DEPENDENCIES| The Java dependencies that came from community sources such as Maven central.| |
|SBOM_JAVA_COMPONENTS_COUNT| The counting of Java components by publisher in JSON format| |
### deprecated-image-check:0.4 task results
|name|description|used in params (taskname:taskrefversion:taskparam)
|---|---|---|
|IMAGES_PROCESSED| Images processed in the task.| |
|TEST_OUTPUT| Tekton task test output.| |
### fbc-related-image-check:0.1 task results
|name|description|used in params (taskname:taskrefversion:taskparam)
|---|---|---|
|TEST_OUTPUT| Tekton task test output.| |
### fbc-validation:0.1 task results
|name|description|used in params (taskname:taskrefversion:taskparam)
|---|---|---|
|TEST_OUTPUT| Tekton task test output.| |
### git-clone:0.1 task results
|name|description|used in params (taskname:taskrefversion:taskparam)
|---|---|---|
|commit| The precise commit SHA that was fetched by this Task.| build-container:0.1:COMMIT_SHA|
|commit-timestamp| The commit timestamp of the checkout| |
|url| The precise URL that was fetched by this Task.| show-summary:0.2:git-url|
### init:0.2 task results
|name|description|used in params (taskname:taskrefversion:taskparam)
|---|---|---|
|build| Defines if the image in param image-url should be built| |
### inspect-image:0.1 task results
|name|description|used in params (taskname:taskrefversion:taskparam)
|---|---|---|
|BASE_IMAGE| Base image source image is built from.| fbc-validate:0.1:BASE_IMAGE|
|BASE_IMAGE_REPOSITORY| Base image repository URL.| |
|TEST_OUTPUT| Tekton task test output.| |
### push-dockerfile:0.1 task results
|name|description|used in params (taskname:taskrefversion:taskparam)
|---|---|---|
|IMAGE_REF| Digest-pinned image reference to the Dockerfile image.| |
### sbom-json-check:0.1 task results
|name|description|used in params (taskname:taskrefversion:taskparam)
|---|---|---|
|IMAGES_PROCESSED| Images processed in the task.| |
|TEST_OUTPUT| Tekton task test output.| |

## Workspaces
|name|description|optional|used in tasks
|---|---|---|---|
|git-auth| |True| clone-repository:0.1:basic-auth|
|netrc| |True| |
|workspace| |False| show-summary:0.2:workspace ; clone-repository:0.1:output ; build-container:0.1:source ; push-dockerfile:0.1:workspace ; inspect-image:0.1:source ; fbc-validate:0.1:workspace ; fbc-related-image-check:0.1:workspace|
## Available workspaces from tasks
### buildah:0.1 task workspaces
|name|description|optional|workspace from pipeline
|---|---|---|---|
|source| Workspace containing the source code to build.| False| workspace|
### fbc-related-image-check:0.1 task workspaces
|name|description|optional|workspace from pipeline
|---|---|---|---|
|workspace| | False| workspace|
### fbc-validation:0.1 task workspaces
|name|description|optional|workspace from pipeline
|---|---|---|---|
|workspace| | False| workspace|
### git-clone:0.1 task workspaces
|name|description|optional|workspace from pipeline
|---|---|---|---|
|basic-auth| A Workspace containing a .gitconfig and .git-credentials file or username and password. These will be copied to the user's home before any git commands are run. Any other files in this Workspace are ignored. It is strongly recommended to use ssh-directory over basic-auth whenever possible and to bind a Secret to this Workspace over other volume types. | True| git-auth|
|output| The git repo will be cloned onto the volume backing this Workspace.| False| workspace|
|ssh-directory| A .ssh directory with private key, known_hosts, config, etc. Copied to the user's home before git commands are executed. Used to authenticate with the git remote when performing the clone. Binding a Secret to this Workspace is strongly recommended over other volume types. | True| |
### inspect-image:0.1 task workspaces
|name|description|optional|workspace from pipeline
|---|---|---|---|
|source| | False| workspace|
### push-dockerfile:0.1 task workspaces
|name|description|optional|workspace from pipeline
|---|---|---|---|
|workspace| Workspace containing the source code from where the Dockerfile is discovered.| False| workspace|
### summary:0.2 task workspaces
|name|description|optional|workspace from pipeline
|---|---|---|---|
|workspace| The workspace where source code is included.| True| workspace|
