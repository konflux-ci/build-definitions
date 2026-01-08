# "package-operator-package pipeline"
Given a git repository, a reference (as in, tag or commit) and a path within the repository this pipeline will create a package-operator package.

The process of how a pko package is defined and packaged is documented [here](https://package-operator.run/docs/guides/packaging-an-application/). This task expects the package definition, will build it using `kubectl-package` and push the created package to the given OCI registry destination.

## Parameters
|name|description|default value|used in (taskname:taskrefversion:taskparam)|
|---|---|---|---|
|build-image-index| Add built image into an OCI image index| false| build-image-index:0.2:ALWAYS_BUILD_INDEX|
|build-source-image| Build a source image.| false| |
|buildah-format| The format for the resulting image's mediaType. Valid values are oci or docker.| docker| build-image-index:0.2:BUILDAH_FORMAT|
|enable-cache-proxy| Enable cache proxy configuration| false| init:0.2:enable-cache-proxy|
|git-url| Source Repository URL| None| clone-repository:0.1:url|
|hermetic| Execute the build with network isolation| false| |
|image-expires-after| Image tag expiration time, time values could be something like 1h, 2d, 3w for hours, days, and weeks, respectively.| | build-image-index:0.2:IMAGE_EXPIRES_AFTER|
|output-image| Fully Qualified Output Image| None| init:0.2:image-url ; build-container:0.1:DST_URL ; build-image-index:0.2:IMAGE|
|path-context| Path to the source code of an application's component from where to build image.| .| build-container:0.1:SRC_PATH|
|prefetch-input| Build dependencies to be prefetched| | prefetch-dependencies:0.2:input|
|rebuild| Force rebuild image| false| init:0.2:rebuild|
|revision| Revision of the Source Repository| | clone-repository:0.1:revision|
|skip-checks| Skip checks against built image| false| init:0.2:skip-checks|

## Available params from tasks
### apply-tags:0.2 task parameters
|name|description|default value|already set by|
|---|---|---|---|
|ADDITIONAL_TAGS| Additional tags that will be applied to the image in the registry.| []| |
|CA_TRUST_CONFIG_MAP_KEY| The name of the key in the ConfigMap that contains the CA bundle data.| ca-bundle.crt| |
|CA_TRUST_CONFIG_MAP_NAME| The name of the ConfigMap to read CA bundle data from.| trusted-ca| |
|IMAGE_DIGEST| Image digest of the built image.| None| '$(tasks.build-image-index.results.IMAGE_DIGEST)'|
|IMAGE_URL| Image repository and tag reference of the the built image.| None| '$(tasks.build-image-index.results.IMAGE_URL)'|
### build-image-index:0.2 task parameters
|name|description|default value|already set by|
|---|---|---|---|
|ALWAYS_BUILD_INDEX| Build an image index even if IMAGES is of length 1. Default true. If the image index generation is skipped, the task will forward values for params.IMAGES[0] to results.IMAGE_*. In order to properly set all results, use the repository:tag@sha256:digest format for the IMAGES parameter.| true| '$(params.build-image-index)'|
|BUILDAH_FORMAT| The format for the resulting image's mediaType. Valid values are oci (default) or docker.| oci| '$(params.buildah-format)'|
|COMMIT_SHA| The commit the image is built from.| ""| '$(tasks.clone-repository.results.commit)'|
|IMAGE| The target image and tag where the image will be pushed to.| None| '$(params.output-image)'|
|IMAGES| List of Image Manifests to be referenced by the Image Index| None| '['$(tasks.build-container.results.IMAGE_URL)@$(tasks.build-container.results.IMAGE_DIGEST)']'|
|IMAGE_EXPIRES_AFTER| Delete image tag after specified time resulting in garbage collection of the digest. Empty means to keep the image tag. Time values could be something like 1h, 2d, 3w for hours, days, and weeks, respectively.| ""| '$(params.image-expires-after)'|
|SBOM_SKIP_VALIDATION| Flag to enable or disable SBOM validation before save. Validation is optional - use this if you are experiencing performance issues.| false| |
|STORAGE_DRIVER| Storage driver to configure for buildah| vfs| |
|TLSVERIFY| Verify the TLS on the registry endpoint (for push/pull to a non-TLS registry)| true| |
|caTrustConfigMapKey| The name of the key in the ConfigMap that contains the CA bundle data| ca-bundle.crt| |
|caTrustConfigMapName| The name of the ConfigMap to read CA bundle data from| trusted-ca| |
### clair-scan:0.3 task parameters
|name|description|default value|already set by|
|---|---|---|---|
|ca-trust-config-map-key| The name of the key in the ConfigMap that contains the CA bundle data.| ca-bundle.crt| |
|ca-trust-config-map-name| The name of the ConfigMap to read CA bundle data from.| trusted-ca| |
|docker-auth| unused, should be removed in next task version.| ""| |
|image-digest| Image digest to scan.| None| '$(tasks.build-image-index.results.IMAGE_DIGEST)'|
|image-platform| The platform built by.| ""| |
|image-url| Image URL.| None| '$(tasks.build-image-index.results.IMAGE_URL)'|
### clamav-scan:0.3 task parameters
|name|description|default value|already set by|
|---|---|---|---|
|ca-trust-config-map-key| The name of the key in the ConfigMap that contains the CA bundle data.| ca-bundle.crt| |
|ca-trust-config-map-name| The name of the ConfigMap to read CA bundle data from.| trusted-ca| |
|clamd-max-threads| Maximum number of threads clamd runs.| 8| |
|docker-auth| unused| ""| |
|image-arch| Image arch.| ""| |
|image-digest| Image digest to scan.| None| '$(tasks.build-image-index.results.IMAGE_DIGEST)'|
|image-url| Image URL.| None| '$(tasks.build-image-index.results.IMAGE_URL)'|
### coverity-availability-check:0.2 task parameters
|name|description|default value|already set by|
|---|---|---|---|
|AUTH_TOKEN_COVERITY_IMAGE| Name of secret which contains the authentication token for pulling the Coverity image.| auth-token-coverity-image| |
|COV_LICENSE| Name of secret which contains the Coverity license| cov-license| |
### deprecated-image-check:0.5 task parameters
|name|description|default value|already set by|
|---|---|---|---|
|BASE_IMAGES_DIGESTS| Digests of base build images.| ""| |
|CA_TRUST_CONFIG_MAP_KEY| The name of the key in the ConfigMap that contains the CA bundle data.| ca-bundle.crt| |
|CA_TRUST_CONFIG_MAP_NAME| The name of the ConfigMap to read CA bundle data from.| trusted-ca| |
|IMAGE_DIGEST| Image digest.| None| '$(tasks.build-image-index.results.IMAGE_DIGEST)'|
|IMAGE_URL| Fully qualified image name.| None| '$(tasks.build-image-index.results.IMAGE_URL)'|
|POLICY_DIR| Path to directory containing Conftest policies.| /project/repository/| |
|POLICY_NAMESPACE| Namespace for Conftest policy.| required_checks| |
### ecosystem-cert-preflight-checks:0.2 task parameters
|name|description|default value|already set by|
|---|---|---|---|
|artifact-type| The type of artifact. Select from application, operatorbundle, or introspect.| introspect| |
|ca-trust-config-map-key| The name of the key in the ConfigMap that contains the CA bundle data.| ca-bundle.crt| |
|ca-trust-config-map-name| The name of the ConfigMap to read CA bundle data from.| trusted-ca| |
|image-url| Image url to scan.| None| '$(tasks.build-image-index.results.IMAGE_URL)'|
|platform| The platform the image is built on.| ""| |
### git-clone:0.1 task parameters
|name|description|default value|already set by|
|---|---|---|---|
|caTrustConfigMapKey| The name of the key in the ConfigMap that contains the CA bundle data.| ca-bundle.crt| |
|caTrustConfigMapName| The name of the ConfigMap to read CA bundle data from.| trusted-ca| |
|deleteExisting| Clean out the contents of the destination directory if it already exists before cloning.| true| |
|depth| Perform a shallow clone, fetching only the most recent N commits.| 1| |
|enableSymlinkCheck| Check symlinks in the repo. If they're pointing outside of the repo, the build will fail. | true| |
|fetchTags| Fetch all tags for the repo.| false| |
|gitInitImage| Deprecated. Has no effect. Will be removed in the future.| ""| |
|httpProxy| HTTP proxy server for non-SSL requests.| ""| |
|httpsProxy| HTTPS proxy server for SSL requests.| ""| |
|mergeSourceDepth| Perform a shallow fetch of the target branch, fetching only the most recent N commits. If empty, fetches the full history of the target branch. | ""| |
|mergeSourceRepoUrl| URL of the repository to fetch the target branch from when mergeTargetBranch is true. If empty, uses the same repository (origin). This allows merging a branch from a different repository. | ""| |
|mergeTargetBranch| Set to "true" to merge the targetBranch into the checked-out revision.| false| |
|noProxy| Opt out of proxying HTTP/HTTPS requests.| ""| |
|refspec| Refspec to fetch before checking out revision.| ""| |
|revision| Revision to checkout. (branch, tag, sha, ref, etc...)| ""| '$(params.revision)'|
|shortCommitLength| Length of short commit SHA| 7| |
|sparseCheckoutDirectories| Define the directory patterns to match or exclude when performing a sparse checkout.| ""| |
|sslVerify| Set the `http.sslVerify` global git config. Setting this to `false` is not advised unless you are sure that you trust your git remote.| true| |
|subdirectory| Subdirectory inside the `output` Workspace to clone the repo into.| source| |
|submodulePaths| Comma-separated list of specific submodule paths to initialize and fetch. Only submodules in the specified directories and their subdirectories will be fetched. Empty string fetches all submodules. Parameter "submodules" must be set to "true" to make this parameter applicable. | ""| |
|submodules| Initialize and fetch git submodules.| true| |
|targetBranch| The target branch to merge into the revision (if mergeTargetBranch is true).| main| |
|url| Repository URL to clone from.| None| '$(params.git-url)'|
|userHome| Absolute path to the user's home directory. Set this explicitly if you are running the image as a non-root user. | /tekton/home| |
|verbose| Log the commands that are executed during `git-clone`'s operation.| false| |
### init:0.2 task parameters
|name|description|default value|already set by|
|---|---|---|---|
|enable-cache-proxy| Enable cache proxy configuration| false| '$(params.enable-cache-proxy)'|
|image-url| Image URL for build by PipelineRun| None| '$(params.output-image)'|
|rebuild| Rebuild the image if exists| false| '$(params.rebuild)'|
|skip-checks| Skip checks against built image| false| '$(params.skip-checks)'|
### package-operator-package:0.1 task parameters
|name|description|default value|already set by|
|---|---|---|---|
|DST_URL| URL where to push the generated pko package to.| None| '$(params.output-image)'|
|SRC_PATH| Path of the directory within the repository that contains package manifest.| None| '$(params.path-context)'|
### prefetch-dependencies:0.2 task parameters
|name|description|default value|already set by|
|---|---|---|---|
|ACTIVATION_KEY| Name of secret which contains subscription activation key| activation-key| |
|caTrustConfigMapKey| The name of the key in the ConfigMap that contains the CA bundle data.| ca-bundle.crt| |
|caTrustConfigMapName| The name of the ConfigMap to read CA bundle data from.| trusted-ca| |
|config-file-content| Pass configuration to the prefetch tool. Note this needs to be passed as a YAML-formatted config dump, not as a file path! | ""| |
|dev-package-managers| Enable in-development package managers. WARNING: the behavior may change at any time without notice. Use at your own risk. | false| |
|input| Configures project packages that will have their dependencies prefetched.| None| '$(params.prefetch-input)'|
|log-level| Set prefetch tool log level (debug, info, warning, error)| info| |
|mode| Control how input requirement violations are handled: strict (errors) or permissive (warnings).| strict| |
|sbom-type| Select the SBOM format to generate. Valid values: spdx, cyclonedx.| spdx| |
### rpms-signature-scan:0.2 task parameters
|name|description|default value|already set by|
|---|---|---|---|
|ca-trust-config-map-key| The name of the key in the ConfigMap that contains the CA bundle data.| ca-bundle.crt| |
|ca-trust-config-map-name| The name of the ConfigMap to read CA bundle data from.| trusted-ca| |
|image-digest| Image digest to scan| None| '$(tasks.build-image-index.results.IMAGE_DIGEST)'|
|image-url| Image URL| None| '$(tasks.build-image-index.results.IMAGE_URL)'|
|workdir| Directory that will be used for storing temporary files produced by this task. | /tmp| |
### sast-coverity-check:0.3 task parameters
|name|description|default value|already set by|
|---|---|---|---|
|ACTIVATION_KEY| Name of secret which contains subscription activation key| activation-key| |
|ADDITIONAL_BASE_IMAGES| Additional base image references to include to the SBOM. Array of image_reference_with_digest strings| []| |
|ADDITIONAL_SECRET| Name of a secret which will be made available to the build with 'buildah build --secret' at /run/secrets/$ADDITIONAL_SECRET| does-not-exist| |
|ADD_CAPABILITIES| Comma separated list of extra capabilities to add when running 'buildah build'| ""| |
|ANNOTATIONS| Additional key=value annotations that should be applied to the image| []| |
|ANNOTATIONS_FILE| Path to a file with additional key=value annotations that should be applied to the image| ""| |
|BUILDAH_FORMAT| The format for the resulting image's mediaType. Valid values are oci (default) or docker.| oci| |
|BUILD_ARGS| Array of --build-arg values ("arg=value" strings)| []| |
|BUILD_ARGS_FILE| Path to a file with build arguments, see https://www.mankier.com/1/buildah-build#--build-arg-file| ""| |
|COMMIT_SHA| The image is built from this commit.| ""| |
|CONTEXT| Path to the directory to use as context.| .| |
|COV_ANALYZE_ARGS| Arguments to be appended to the cov-analyze command| --enable HARDCODED_CREDENTIALS --security --concurrency --spotbugs-max-mem=4096| |
|COV_LICENSE| Name of secret which contains the Coverity license| cov-license| |
|DOCKERFILE| Path to the Dockerfile to build.| ./Dockerfile| |
|ENTITLEMENT_SECRET| Name of secret which contains the entitlement certificates| etc-pki-entitlement| |
|HERMETIC| Determines if build will be executed without network access.| false| |
|HTTP_PROXY| HTTP/HTTPS proxy to use for the buildah pull and build operations. Will not be passed through to the container during the build process.| ""| |
|ICM_KEEP_COMPAT_LOCATION| Whether to keep compatibility location at /root/buildinfo/ for ICM injection| true| |
|IMAGE| The task will build a container image and tag it locally as $IMAGE, but will not push the image anywhere. Due to the relationship between this task and the buildah task, the parameter is required, but its value is mostly irrelevant.| None| |
|IMAGE_EXPIRES_AFTER| Delete image tag after specified time. Empty means to keep the image tag. Time values could be something like 1h, 2d, 3w for hours, days, and weeks, respectively.| ""| |
|IMP_FINDINGS_ONLY| Report only important findings. Default is true. To report all findings, specify "false"| true| |
|INHERIT_BASE_IMAGE_LABELS| Determines if the image inherits the base image labels.| true| |
|KFP_GIT_URL| Known False Positives (KFP) git URL (optionally taking a revision delimited by \#). Defaults to "SITE_DEFAULT", which means the default value "https://gitlab.cee.redhat.com/osh/known-false-positives.git" for internal Konflux instance and empty string for external Konflux instance. If set to an empty string, the KFP filtering is disabled.| SITE_DEFAULT| |
|LABELS| Additional key=value labels that should be applied to the image| []| |
|NO_PROXY| Comma separated list of hosts or domains which should bypass the HTTP/HTTPS proxy.| ""| |
|PREFETCH_INPUT| In case it is not empty, the prefetched content should be made available to the build.| ""| |
|PRIVILEGED_NESTED| Whether to enable privileged mode, should be used only with remote VMs| false| |
|PROJECT_NAME| | ""| |
|PROXY_CA_TRUST_CONFIG_MAP_KEY| The name of the key in the ConfigMap that contains the proxy CA bundle data.| ca-bundle.crt| |
|PROXY_CA_TRUST_CONFIG_MAP_NAME| The name of the ConfigMap to read proxy CA bundle data from.| proxy-ca-bundle| |
|RECORD_EXCLUDED| | false| |
|SBOM_TYPE| Select the SBOM format to generate. Valid values: spdx, cyclonedx. Note: the SBOM from the prefetch task - if there is one - must be in the same format.| spdx| |
|SKIP_SBOM_GENERATION| Skip SBOM-related operations. This will likely cause EC policies to fail if enabled| false| |
|SKIP_UNUSED_STAGES| Whether to skip stages in Containerfile that seem unused by subsequent stages| true| |
|SQUASH| Squash all new and previous layers added as a part of this build, as per --squash| false| |
|STORAGE_DRIVER| Storage driver to configure for buildah| overlay| |
|TARGET_DIRS| Target directories in component's source code. Multiple values should be separated with commas. This only applies to buildless capture, which is only attempted if buildful capture fails to produce and results.| .| |
|TARGET_STAGE| Target stage in Dockerfile to build. If not specified, the Dockerfile is processed entirely to (and including) its last stage.| ""| |
|TLSVERIFY| Verify the TLS on the registry endpoint (for push/pull to a non-TLS registry)| true| |
|WORKINGDIR_MOUNT| Mount the current working directory into the build using --volume $PWD:/$WORKINGDIR_MOUNT. Note that the $PWD will be the context directory for the build (see the CONTEXT param).| ""| |
|YUM_REPOS_D_FETCHED| Path in source workspace where dynamically-fetched repos are present| fetched.repos.d| |
|YUM_REPOS_D_SRC| Path in the git repository in which yum repository files are stored| repos.d| |
|YUM_REPOS_D_TARGET| Target path on the container in which yum repository files should be made available| /etc/yum.repos.d| |
|caTrustConfigMapKey| The name of the key in the ConfigMap that contains the CA bundle data.| ca-bundle.crt| |
|caTrustConfigMapName| The name of the ConfigMap to read CA bundle data from.| trusted-ca| |
|image-digest| Digest of the image to which the scan results should be associated.| None| '$(tasks.build-image-index.results.IMAGE_DIGEST)'|
|image-url| URL of the image to which the scan results should be associated.| None| '$(tasks.build-image-index.results.IMAGE_URL)'|
### sast-shell-check:0.1 task parameters
|name|description|default value|already set by|
|---|---|---|---|
|IMP_FINDINGS_ONLY| Whether to include important findings only| true| |
|KFP_GIT_URL| Known False Positives (KFP) git URL (optionally taking a revision delimited by \#). Defaults to "SITE_DEFAULT", which means the default value "https://gitlab.cee.redhat.com/osh/known-false-positives.git" for internal Konflux instance and empty string for external Konflux instance. If set to an empty string, the KFP filtering is disabled.| SITE_DEFAULT| |
|PROJECT_NAME| Name of the scanned project, used to find path exclusions. By default, the Konflux component name will be used.| ""| |
|RECORD_EXCLUDED| Whether to record the excluded findings (default to false). If `true`, the excluded findings will be stored in `excluded-findings.json`. | false| |
|TARGET_DIRS| Target directories in component's source code. Multiple values should be separated with commas.| .| |
|caTrustConfigMapKey| The name of the key in the ConfigMap that contains the CA bundle data.| ca-bundle.crt| |
|caTrustConfigMapName| The name of the ConfigMap to read CA bundle data from.| trusted-ca| |
|image-digest| Image digest to report findings for.| ""| '$(tasks.build-image-index.results.IMAGE_DIGEST)'|
|image-url| Image URL.| ""| '$(tasks.build-image-index.results.IMAGE_URL)'|
### sast-snyk-check:0.4 task parameters
|name|description|default value|already set by|
|---|---|---|---|
|ARGS| Append arguments.| ""| |
|IGNORE_FILE_PATHS| Directories or files to be excluded from Snyk scan (Comma-separated). Useful to split the directories of a git repo across multiple components.| ""| |
|IMP_FINDINGS_ONLY| Report only important findings. Default is true. To report all findings, specify "false"| true| |
|KFP_GIT_URL| Known False Positives (KFP) git URL (optionally taking a revision delimited by \#). Defaults to "SITE_DEFAULT", which means the default value "https://gitlab.cee.redhat.com/osh/known-false-positives.git" for internal Konflux instance and empty string for external Konflux instance. If set to an empty string, the KFP filtering is disabled.| SITE_DEFAULT| |
|PROJECT_NAME| Name of the scanned project, used to find path exclusions. By default, the Konflux component name will be used.| ""| |
|RECORD_EXCLUDED| Write excluded records in file. Useful for auditing (defaults to false).| false| |
|SNYK_SECRET| Name of secret which contains Snyk token.| snyk-secret| |
|TARGET_DIRS| Target directories in component's source code. Multiple values should be separated with commas.| .| |
|caTrustConfigMapKey| The name of the key in the ConfigMap that contains the CA bundle data.| ca-bundle.crt| |
|caTrustConfigMapName| The name of the ConfigMap to read CA bundle data from.| trusted-ca| |
|image-digest| Digest of the image to scan.| None| '$(tasks.build-image-index.results.IMAGE_DIGEST)'|
|image-url| Image URL.| None| '$(tasks.build-image-index.results.IMAGE_URL)'|
### sast-unicode-check:0.3 task parameters
|name|description|default value|already set by|
|---|---|---|---|
|FIND_UNICODE_CONTROL_ARGS| arguments for find-unicode-control command.| -p bidi -v -d -t| |
|FIND_UNICODE_CONTROL_GIT_URL| URL from repository to find unicode control.| https://github.com/siddhesh/find-unicode-control.git#c2accbfbba7553a8bc1ebd97089ae08ad8347e58| |
|KFP_GIT_URL| Known False Positives (KFP) git URL (optionally taking a revision delimited by \#). Defaults to "SITE_DEFAULT", which means the default value "https://gitlab.cee.redhat.com/osh/known-false-positives.git" for internal Konflux instance and empty string for external Konflux instance. If set to an empty string, the KFP filtering is disabled.| SITE_DEFAULT| |
|PROJECT_NAME| Name of the scanned project, used to find path exclusions. By default, the Konflux component name will be used.| ""| |
|RECORD_EXCLUDED| Whether to record the excluded findings (defaults to false). If `true`, the excluded findings will be stored in `excluded-findings.json`. | false| |
|caTrustConfigMapKey| The name of the key in the ConfigMap that contains the CA bundle data.| ca-bundle.crt| |
|caTrustConfigMapName| The name of the ConfigMap to read CA bundle data from.| trusted-ca| |
|image-digest| Image digest used for ORAS upload.| None| '$(tasks.build-image-index.results.IMAGE_DIGEST)'|
|image-url| Image URL used for ORAS upload.| None| '$(tasks.build-image-index.results.IMAGE_URL)'|
### source-build:0.3 task parameters
|name|description|default value|already set by|
|---|---|---|---|
|BASE_IMAGES| By default, the task inspects the SBOM of the binary image to find the base image. With this parameter, you can override that behavior and pass the base image directly. The value should be a newline-separated list of images, in the same order as the FROM instructions specified in a multistage Dockerfile.| ""| |
|BINARY_IMAGE| Binary image name with tag.| None| '$(tasks.build-image-index.results.IMAGE_URL)'|
|BINARY_IMAGE_DIGEST| Digest of the binary image.| None| '$(tasks.build-image-index.results.IMAGE_DIGEST)'|
|IGNORE_UNSIGNED_IMAGE| When set to "true", source build task won't fail when source image is missing signatures (this can be used for development)| false| |
|caTrustConfigMapKey| The name of the key in the ConfigMap that contains the CA bundle data.| ca-bundle.crt| |
|caTrustConfigMapName| The name of the ConfigMap to read CA bundle data from.| trusted-ca| |

## Results
|name|description|value|
|---|---|---|
|CHAINS-GIT_COMMIT| |$(tasks.clone-repository.results.commit)|
|CHAINS-GIT_URL| |$(tasks.clone-repository.results.url)|
|IMAGE_DIGEST| |$(tasks.build-image-index.results.IMAGE_DIGEST)|
|IMAGE_URL| |$(tasks.build-image-index.results.IMAGE_URL)|
## Available results from tasks
### build-image-index:0.2 task results
|name|description|used in params (taskname:taskrefversion:taskparam)
|---|---|---|
|IMAGES| List of all referenced image manifests| |
|IMAGE_DIGEST| Digest of the image just built| build-source-image:0.3:BINARY_IMAGE_DIGEST ; deprecated-base-image-check:0.5:IMAGE_DIGEST ; clair-scan:0.3:image-digest ; sast-snyk-check:0.4:image-digest ; clamav-scan:0.3:image-digest ; sast-coverity-check:0.3:image-digest ; sast-shell-check:0.1:image-digest ; sast-unicode-check:0.3:image-digest ; apply-tags:0.2:IMAGE_DIGEST ; rpms-signature-scan:0.2:image-digest|
|IMAGE_REF| Image reference of the built image containing both the repository and the digest| |
|IMAGE_URL| Image repository and tag where the built image was pushed| build-source-image:0.3:BINARY_IMAGE ; deprecated-base-image-check:0.5:IMAGE_URL ; clair-scan:0.3:image-url ; ecosystem-cert-preflight-checks:0.2:image-url ; sast-snyk-check:0.4:image-url ; clamav-scan:0.3:image-url ; sast-coverity-check:0.3:image-url ; sast-shell-check:0.1:image-url ; sast-unicode-check:0.3:image-url ; apply-tags:0.2:IMAGE_URL ; rpms-signature-scan:0.2:image-url|
|SBOM_BLOB_URL| Reference of SBOM blob digest to enable digest-based verification from provenance| |
### clair-scan:0.3 task results
|name|description|used in params (taskname:taskrefversion:taskparam)
|---|---|---|
|IMAGES_PROCESSED| Images processed in the task.| |
|REPORTS| Mapping of image digests to report digests| |
|SCAN_OUTPUT| Clair scan result.| |
|TEST_OUTPUT| Tekton task test output.| |
### clamav-scan:0.3 task results
|name|description|used in params (taskname:taskrefversion:taskparam)
|---|---|---|
|IMAGES_PROCESSED| Images processed in the task.| |
|TEST_OUTPUT| Tekton task test output.| |
### coverity-availability-check:0.2 task results
|name|description|used in params (taskname:taskrefversion:taskparam)
|---|---|---|
|STATUS| Tekton task simple status to be later checked| |
|TEST_OUTPUT| Tekton task result output.| |
### deprecated-image-check:0.5 task results
|name|description|used in params (taskname:taskrefversion:taskparam)
|---|---|---|
|IMAGES_PROCESSED| Images processed in the task.| |
|TEST_OUTPUT| Tekton task test output.| |
### ecosystem-cert-preflight-checks:0.2 task results
|name|description|used in params (taskname:taskrefversion:taskparam)
|---|---|---|
|ARTIFACT_TYPE| The artifact type, either introspected or set.| |
|ARTIFACT_TYPE_SET_BY| How the artifact type was set.| |
|IMAGES_PROCESSED| Collected image digests| |
|TEST_OUTPUT| Ecosystem checks pass or fail outcome.| |
### git-clone:0.1 task results
|name|description|used in params (taskname:taskrefversion:taskparam)
|---|---|---|
|CHAINS-GIT_COMMIT| The precise commit SHA that was fetched by this Task. This result uses Chains type hinting to include in the provenance.| |
|CHAINS-GIT_URL| The precise URL that was fetched by this Task. This result uses Chains type hinting to include in the provenance.| |
|commit| The precise commit SHA that was fetched by this Task.| build-image-index:0.2:COMMIT_SHA|
|commit-timestamp| The commit timestamp of the checkout| |
|merged_sha| The SHA of the commit after merging the target branch (if the param mergeTargetBranch is true).| |
|short-commit| The commit SHA that was fetched by this Task limited to params.shortCommitLength number of characters| |
|url| The precise URL that was fetched by this Task.| |
### init:0.2 task results
|name|description|used in params (taskname:taskrefversion:taskparam)
|---|---|---|
|build| Defines if the image in param image-url should be built| |
|http-proxy| HTTP proxy URL for cache proxy (when enable-cache-proxy is true)| |
|no-proxy| NO_PROXY value for cache proxy (when enable-cache-proxy is true)| |
### package-operator-package:0.1 task results
|name|description|used in params (taskname:taskrefversion:taskparam)
|---|---|---|
|IMAGE_DIGEST| Digest of the package just built| |
|IMAGE_REF| Image reference of the built package| |
|IMAGE_URL| Image repository and tag where the built package was pushed| build-image-index:0.2:IMAGES|
|SBOM_BLOB_URL| Reference of SBOM blob digest to enable digest-based verification from provenance| |
### rpms-signature-scan:0.2 task results
|name|description|used in params (taskname:taskrefversion:taskparam)
|---|---|---|
|IMAGES_PROCESSED| Images processed in the task.| |
|RPMS_DATA| Information about signed and unsigned RPMs| |
|TEST_OUTPUT| Tekton task test output.| |
### sast-coverity-check:0.3 task results
|name|description|used in params (taskname:taskrefversion:taskparam)
|---|---|---|
|TEST_OUTPUT| Tekton task test output.| |
### sast-shell-check:0.1 task results
|name|description|used in params (taskname:taskrefversion:taskparam)
|---|---|---|
|TEST_OUTPUT| Tekton task test output.| |
### sast-snyk-check:0.4 task results
|name|description|used in params (taskname:taskrefversion:taskparam)
|---|---|---|
|TEST_OUTPUT| Tekton task test output.| |
### sast-unicode-check:0.3 task results
|name|description|used in params (taskname:taskrefversion:taskparam)
|---|---|---|
|TEST_OUTPUT| Tekton task test output.| |
### source-build:0.3 task results
|name|description|used in params (taskname:taskrefversion:taskparam)
|---|---|---|
|BUILD_RESULT| Build result.| |
|IMAGE_REF| Image reference of the built image.| |
|SOURCE_IMAGE_DIGEST| The source image digest.| |
|SOURCE_IMAGE_URL| The source image url.| |

## Workspaces
|name|description|optional|used in tasks
|---|---|---|---|
|git-auth| |True| clone-repository:0.1:basic-auth ; prefetch-dependencies:0.2:git-basic-auth|
|netrc| |True| prefetch-dependencies:0.2:netrc|
|workspace| |False| clone-repository:0.1:output ; prefetch-dependencies:0.2:source ; build-container:0.1:package ; build-source-image:0.3:workspace ; sast-snyk-check:0.4:workspace ; sast-coverity-check:0.3:source ; sast-shell-check:0.1:workspace ; sast-unicode-check:0.3:workspace|
## Available workspaces from tasks
### git-clone:0.1 task workspaces
|name|description|optional|workspace from pipeline
|---|---|---|---|
|basic-auth| A Workspace containing a .gitconfig and .git-credentials file or username and password. These will be copied to the user's home before any git commands are run. Any other files in this Workspace are ignored. It is strongly recommended to use ssh-directory over basic-auth whenever possible and to bind a Secret to this Workspace over other volume types. | True| git-auth|
|output| The git repo will be cloned onto the volume backing this Workspace.| False| workspace|
|ssh-directory| A .ssh directory with private key, known_hosts, config, etc. Copied to the user's home before git commands are executed. Used to authenticate with the git remote when performing the clone. Binding a Secret to this Workspace is strongly recommended over other volume types. | True| |
### package-operator-package:0.1 task workspaces
|name|description|optional|workspace from pipeline
|---|---|---|---|
|source| Workspace containing the source code to build.| False| workspace|
### prefetch-dependencies:0.2 task workspaces
|name|description|optional|workspace from pipeline
|---|---|---|---|
|git-basic-auth| A Workspace containing a .gitconfig and .git-credentials file or username and password. These will be copied to the user's home before prefetch is run. Any other files in this Workspace are ignored. It is strongly recommended to bind a Secret to this Workspace over other volume types. | True| git-auth|
|netrc| Workspace containing a .netrc file. Prefetch will use the credentials in this file when performing http(s) requests. | True| netrc|
|source| Workspace with the source code, prefetch artifacts will be stored on the workspace as well| False| workspace|
### sast-coverity-check:0.3 task workspaces
|name|description|optional|workspace from pipeline
|---|---|---|---|
|source| Workspace containing the source code to build.| False| workspace|
### sast-shell-check:0.1 task workspaces
|name|description|optional|workspace from pipeline
|---|---|---|---|
|workspace| | False| workspace|
### sast-snyk-check:0.4 task workspaces
|name|description|optional|workspace from pipeline
|---|---|---|---|
|workspace| | False| workspace|
### sast-unicode-check:0.3 task workspaces
|name|description|optional|workspace from pipeline
|---|---|---|---|
|workspace| | False| workspace|
### source-build:0.3 task workspaces
|name|description|optional|workspace from pipeline
|---|---|---|---|
|workspace| The workspace where source code is included.| False| workspace|
