# "tekton-bundle-builder-oci-ta pipeline"

## Parameters
|name|description|default value|used in (taskname:taskrefversion:taskparam)|
|---|---|---|---|
|build-image-index| Add built image into an OCI image index| false| build-image-index:0.1:ALWAYS_BUILD_INDEX|
|build-source-image| Build a source image.| false| |
|dockerfile| Path to the Dockerfile inside the context specified by parameter path-context| Dockerfile| |
|git-url| Source Repository URL| None| clone-repository:0.1:url|
|hermetic| Execute the build with network isolation| false| |
|image-expires-after| Image tag expiration time, time values could be something like 1h, 2d, 3w for hours, days, and weeks, respectively.| | clone-repository:0.1:ociArtifactExpiresAfter ; prefetch-dependencies:0.2:ociArtifactExpiresAfter ; build-image-index:0.1:IMAGE_EXPIRES_AFTER|
|output-image| Fully Qualified Output Image| None| show-summary:0.2:image-url ; init:0.2:image-url ; clone-repository:0.1:ociStorage ; prefetch-dependencies:0.2:ociStorage ; build-container:0.1:IMAGE ; build-image-index:0.1:IMAGE|
|path-context| Path to the source code of an application's component from where to build image.| .| build-container:0.1:CONTEXT|
|prefetch-input| Build dependencies to be prefetched by Cachi2| | prefetch-dependencies:0.2:input|
|rebuild| Force rebuild image| false| init:0.2:rebuild|
|revision| Revision of the Source Repository| | clone-repository:0.1:revision|
|skip-checks| Skip checks against built image| false| init:0.2:skip-checks|

## Available params from tasks
### apply-tags:0.1 task parameters
|name|description|default value|already set by|
|---|---|---|---|
|ADDITIONAL_TAGS| Additional tags that will be applied to the image in the registry.| []| |
|CA_TRUST_CONFIG_MAP_KEY| The name of the key in the ConfigMap that contains the CA bundle data.| ca-bundle.crt| |
|CA_TRUST_CONFIG_MAP_NAME| The name of the ConfigMap to read CA bundle data from.| trusted-ca| |
|IMAGE| Reference of image that was pushed to registry in the buildah task.| None| '$(tasks.build-image-index.results.IMAGE_URL)'|
### build-image-index:0.1 task parameters
|name|description|default value|already set by|
|---|---|---|---|
|ALWAYS_BUILD_INDEX| Build an image index even if IMAGES is of length 1. Default true. If the image index generation is skipped, the task will forward values for params.IMAGES[0] to results.IMAGE_*. In order to properly set all results, use the repository:tag@sha256:digest format for the IMAGES parameter.| true| '$(params.build-image-index)'|
|BUILDAH_FORMAT| The format for the resulting image's mediaType. Valid values are oci (default) or docker.| oci| |
|COMMIT_SHA| The commit the image is built from.| | '$(tasks.clone-repository.results.commit)'|
|IMAGE| The target image and tag where the image will be pushed to.| None| '$(params.output-image)'|
|IMAGES| List of Image Manifests to be referenced by the Image Index| None| '['$(tasks.build-container.results.IMAGE_URL)@$(tasks.build-container.results.IMAGE_DIGEST)']'|
|IMAGE_EXPIRES_AFTER| Delete image tag after specified time resulting in garbage collection of the digest. Empty means to keep the image tag. Time values could be something like 1h, 2d, 3w for hours, days, and weeks, respectively.| | '$(params.image-expires-after)'|
|STORAGE_DRIVER| Storage driver to configure for buildah| vfs| |
|TLSVERIFY| Verify the TLS on the registry endpoint (for push/pull to a non-TLS registry)| true| |
### git-clone-oci-ta:0.1 task parameters
|name|description|default value|already set by|
|---|---|---|---|
|caTrustConfigMapKey| The name of the key in the ConfigMap that contains the CA bundle data.| ca-bundle.crt| |
|caTrustConfigMapName| The name of the ConfigMap to read CA bundle data from.| trusted-ca| |
|depth| Perform a shallow clone, fetching only the most recent N commits.| 1| |
|enableSymlinkCheck| Check symlinks in the repo. If they're pointing outside of the repo, the build will fail. | true| |
|fetchTags| Fetch all tags for the repo.| false| |
|httpProxy| HTTP proxy server for non-SSL requests.| | |
|httpsProxy| HTTPS proxy server for SSL requests.| | |
|noProxy| Opt out of proxying HTTP/HTTPS requests.| | |
|ociArtifactExpiresAfter| Expiration date for the trusted artifacts created in the OCI repository. An empty string means the artifacts do not expire.| | '$(params.image-expires-after)'|
|ociStorage| The OCI repository where the Trusted Artifacts are stored.| None| '$(params.output-image).git'|
|refspec| Refspec to fetch before checking out revision.| | |
|revision| Revision to checkout. (branch, tag, sha, ref, etc...)| | '$(params.revision)'|
|shortCommitLength| Length of short commit SHA| 7| |
|sparseCheckoutDirectories| Define the directory patterns to match or exclude when performing a sparse checkout.| | |
|sslVerify| Set the `http.sslVerify` global git config. Setting this to `false` is not advised unless you are sure that you trust your git remote.| true| |
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
### prefetch-dependencies-oci-ta:0.2 task parameters
|name|description|default value|already set by|
|---|---|---|---|
|ACTIVATION_KEY| Name of secret which contains subscription activation key| activation-key| |
|SOURCE_ARTIFACT| The Trusted Artifact URI pointing to the artifact with the application source code.| None| '$(tasks.clone-repository.results.SOURCE_ARTIFACT)'|
|caTrustConfigMapKey| The name of the key in the ConfigMap that contains the CA bundle data.| ca-bundle.crt| |
|caTrustConfigMapName| The name of the ConfigMap to read CA bundle data from.| trusted-ca| |
|config-file-content| Pass configuration to cachi2. Note this needs to be passed as a YAML-formatted config dump, not as a file path! | | |
|dev-package-managers| Enable in-development package managers. WARNING: the behavior may change at any time without notice. Use at your own risk. | false| |
|input| Configures project packages that will have their dependencies prefetched.| None| '$(params.prefetch-input)'|
|log-level| Set cachi2 log level (debug, info, warning, error)| info| |
|ociArtifactExpiresAfter| Expiration date for the trusted artifacts created in the OCI repository. An empty string means the artifacts do not expire.| | '$(params.image-expires-after)'|
|ociStorage| The OCI repository where the Trusted Artifacts are stored.| None| '$(params.output-image).prefetch'|
|sbom-type| Select the SBOM format to generate. Valid values: spdx, cyclonedx.| spdx| |
### sast-shell-check-oci-ta:0.1 task parameters
|name|description|default value|already set by|
|---|---|---|---|
|CACHI2_ARTIFACT| The Trusted Artifact URI pointing to the artifact with the prefetched dependencies.| | '$(tasks.prefetch-dependencies.results.CACHI2_ARTIFACT)'|
|IMP_FINDINGS_ONLY| Whether to include important findings only| true| |
|KFP_GIT_URL| Known False Positives (KFP) git URL (optionally taking a revision delimited by \#). Defaults to "SITE_DEFAULT", which means the default value "https://gitlab.cee.redhat.com/osh/known-false-positives.git" for internal Konflux instance and empty string for external Konflux instance. If set to an empty string, the KFP filtering is disabled.| SITE_DEFAULT| |
|PROJECT_NAME| Name of the scanned project, used to find path exclusions. By default, the Konflux component name will be used.| | |
|RECORD_EXCLUDED| Whether to record the excluded findings (default to false). If `true`, the excluded findings will be stored in `excluded-findings.json`. | false| |
|SOURCE_ARTIFACT| The Trusted Artifact URI pointing to the artifact with the application source code.| None| '$(tasks.prefetch-dependencies.results.SOURCE_ARTIFACT)'|
|caTrustConfigMapKey| The name of the key in the ConfigMap that contains the CA bundle data.| ca-bundle.crt| |
|caTrustConfigMapName| The name of the ConfigMap to read CA bundle data from.| trusted-ca| |
|image-digest| Image digest to report findings for.| | '$(tasks.build-image-index.results.IMAGE_DIGEST)'|
|image-url| Image URL.| | '$(tasks.build-image-index.results.IMAGE_URL)'|
### sast-unicode-check-oci-ta:0.2 task parameters
|name|description|default value|already set by|
|---|---|---|---|
|CACHI2_ARTIFACT| The Trusted Artifact URI pointing to the artifact with the prefetched dependencies.| | '$(tasks.prefetch-dependencies.results.CACHI2_ARTIFACT)'|
|FIND_UNICODE_CONTROL_ARGS| arguments for find-unicode-control command.| -p bidi -v -d -t| |
|FIND_UNICODE_CONTROL_GIT_URL| URL from repository to find unicode control.| https://github.com/siddhesh/find-unicode-control.git#c2accbfbba7553a8bc1ebd97089ae08ad8347e58| |
|KFP_GIT_URL| Known False Positives (KFP) git URL (optionally taking a revision delimited by \#). Defaults to "SITE_DEFAULT", which means the default value "https://gitlab.cee.redhat.com/osh/known-false-positives.git" for internal Konflux instance and empty string for external Konflux instance. If set to an empty string, the KFP filtering is disabled.| SITE_DEFAULT| |
|PROJECT_NAME| Name of the scanned project, used to find path exclusions. By default, the Konflux component name will be used.| | |
|RECORD_EXCLUDED| Whether to record the excluded findings (defaults to false). If `true`, the excluded findings will be stored in `excluded-findings.json`. | false| |
|SOURCE_ARTIFACT| The Trusted Artifact URI pointing to the artifact with the application source code.| None| '$(tasks.prefetch-dependencies.results.SOURCE_ARTIFACT)'|
|caTrustConfigMapKey| The name of the key in the ConfigMap that contains the CA bundle data.| ca-bundle.crt| |
|caTrustConfigMapName| The name of the ConfigMap to read CA bundle data from.| trusted-ca| |
|image-digest| Image digest| | '$(tasks.build-image-index.results.IMAGE_DIGEST)'|
|image-url| Image URL.| | '$(tasks.build-image-index.results.IMAGE_URL)'|
### summary:0.2 task parameters
|name|description|default value|already set by|
|---|---|---|---|
|build-task-status| State of build task in pipelineRun| Succeeded| '$(tasks.build-image-index.status)'|
|git-url| Git URL| None| '$(tasks.clone-repository.results.url)?rev=$(tasks.clone-repository.results.commit)'|
|image-url| Image URL| None| '$(params.output-image)'|
|pipelinerun-name| pipeline-run to annotate| None| '$(context.pipelineRun.name)'|
### tkn-bundle-oci-ta:0.1 task parameters
|name|description|default value|already set by|
|---|---|---|---|
|CONTEXT| Path to the directory to use as context.| .| '$(params.path-context)'|
|HOME| Value for the HOME environment variable.| /tekton/home| |
|IMAGE| Reference of the image task will produce.| None| '$(params.output-image)'|
|SOURCE_ARTIFACT| The Trusted Artifact URI pointing to the artifact with the application source code.| None| '$(tasks.prefetch-dependencies.results.SOURCE_ARTIFACT)'|
|STEPS_IMAGE| An optional image to configure task steps with in the bundle| | |

## Results
|name|description|value|
|---|---|---|
|CHAINS-GIT_COMMIT| |$(tasks.clone-repository.results.commit)|
|CHAINS-GIT_URL| |$(tasks.clone-repository.results.url)|
|IMAGE_DIGEST| |$(tasks.build-image-index.results.IMAGE_DIGEST)|
|IMAGE_URL| |$(tasks.build-image-index.results.IMAGE_URL)|
## Available results from tasks
### build-image-index:0.1 task results
|name|description|used in params (taskname:taskrefversion:taskparam)
|---|---|---|
|IMAGES| List of all referenced image manifests| |
|IMAGE_DIGEST| Digest of the image just built| sast-shell-check:0.1:image-digest ; sast-unicode-check:0.2:image-digest|
|IMAGE_REF| Image reference of the built image containing both the repository and the digest| |
|IMAGE_URL| Image repository and tag where the built image was pushed| sast-shell-check:0.1:image-url ; sast-unicode-check:0.2:image-url ; apply-tags:0.1:IMAGE|
|SBOM_BLOB_URL| Reference of SBOM blob digest to enable digest-based verification from provenance| |
### git-clone-oci-ta:0.1 task results
|name|description|used in params (taskname:taskrefversion:taskparam)
|---|---|---|
|CHAINS-GIT_COMMIT| The precise commit SHA that was fetched by this Task. This result uses Chains type hinting to include in the provenance.| |
|CHAINS-GIT_URL| The precise URL that was fetched by this Task. This result uses Chains type hinting to include in the provenance.| |
|SOURCE_ARTIFACT| The Trusted Artifact URI pointing to the artifact with the application source code.| prefetch-dependencies:0.2:SOURCE_ARTIFACT|
|commit| The precise commit SHA that was fetched by this Task.| build-image-index:0.1:COMMIT_SHA|
|commit-timestamp| The commit timestamp of the checkout| |
|short-commit| The commit SHA that was fetched by this Task limited to params.shortCommitLength number of characters| |
|url| The precise URL that was fetched by this Task.| show-summary:0.2:git-url|
### init:0.2 task results
|name|description|used in params (taskname:taskrefversion:taskparam)
|---|---|---|
|build| Defines if the image in param image-url should be built| |
### prefetch-dependencies-oci-ta:0.2 task results
|name|description|used in params (taskname:taskrefversion:taskparam)
|---|---|---|
|CACHI2_ARTIFACT| The Trusted Artifact URI pointing to the artifact with the prefetched dependencies.| sast-shell-check:0.1:CACHI2_ARTIFACT ; sast-unicode-check:0.2:CACHI2_ARTIFACT|
|SOURCE_ARTIFACT| The Trusted Artifact URI pointing to the artifact with the application source code.| build-container:0.1:SOURCE_ARTIFACT ; sast-shell-check:0.1:SOURCE_ARTIFACT ; sast-unicode-check:0.2:SOURCE_ARTIFACT|
### sast-shell-check-oci-ta:0.1 task results
|name|description|used in params (taskname:taskrefversion:taskparam)
|---|---|---|
|TEST_OUTPUT| Tekton task test output.| |
### sast-unicode-check-oci-ta:0.2 task results
|name|description|used in params (taskname:taskrefversion:taskparam)
|---|---|---|
|TEST_OUTPUT| Tekton task test output.| |
### tkn-bundle-oci-ta:0.1 task results
|name|description|used in params (taskname:taskrefversion:taskparam)
|---|---|---|
|IMAGE_DIGEST| Digest of the image just built| |
|IMAGE_REF| Image reference of the built image| |
|IMAGE_URL| Image repository and tag where the built image was pushed with tag only| build-image-index:0.1:IMAGES|

## Workspaces
|name|description|optional|used in tasks
|---|---|---|---|
|git-auth| |True| clone-repository:0.1:basic-auth ; prefetch-dependencies:0.2:git-basic-auth|
|netrc| |True| prefetch-dependencies:0.2:netrc|
|sast-results| |False| |
## Available workspaces from tasks
### git-clone-oci-ta:0.1 task workspaces
|name|description|optional|workspace from pipeline
|---|---|---|---|
|basic-auth| A Workspace containing a .gitconfig and .git-credentials file or username and password. These will be copied to the user's home before any git commands are run. Any other files in this Workspace are ignored. It is strongly recommended to use ssh-directory over basic-auth whenever possible and to bind a Secret to this Workspace over other volume types. | True| git-auth|
|ssh-directory| A .ssh directory with private key, known_hosts, config, etc. Copied to the user's home before git commands are executed. Used to authenticate with the git remote when performing the clone. Binding a Secret to this Workspace is strongly recommended over other volume types. | True| |
### prefetch-dependencies-oci-ta:0.2 task workspaces
|name|description|optional|workspace from pipeline
|---|---|---|---|
|git-basic-auth| A Workspace containing a .gitconfig and .git-credentials file or username and password. These will be copied to the user's home before any cachi2 commands are run. Any other files in this Workspace are ignored. It is strongly recommended to bind a Secret to this Workspace over other volume types. | True| git-auth|
|netrc| Workspace containing a .netrc file. Cachi2 will use the credentials in this file when performing http(s) requests. | True| netrc|
### summary:0.2 task workspaces
|name|description|optional|workspace from pipeline
|---|---|---|---|
|workspace| The workspace where source code is included.| True| workspace|
