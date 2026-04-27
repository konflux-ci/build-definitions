# "docker-build-oci-ta-min pipeline"
This pipeline is ideal for building demo container images from a Containerfile while maintaining trust after pipeline customization.

This version of pipeline has minimal resource requests set, it's good for demonstrating and testing.

_Uses `buildah` to create a container image leveraging [trusted artifacts](https://konflux-ci.dev/architecture/ADR/0036-trusted-artifacts.html). It also optionally creates a source image and runs some build-time tests. Information is shared between tasks using OCI artifacts instead of PVCs. EC will pass the [`trusted_task.trusted`](https://conforma.dev/docs/policy/packages/release_trusted_task.html#trusted_task__trusted) policy as long as all data used to build the artifact is generated from trusted tasks.
This pipeline is pushed as a Tekton bundle to [quay.io](https://quay.io/repository/konflux-ci/tekton-catalog/pipeline-docker-build-oci-ta?tab=tags)_

## Parameters
|name|description|default value|used in (taskname:taskrefversion:taskparam)|
|---|---|---|---|
|build-args| Array of --build-arg values ("arg=value" strings) for buildah| []| build-container:0.9:BUILD_ARGS|
|build-args-file| Path to a file with build arguments for buildah, see https://www.mankier.com/1/buildah-build#--build-arg-file| | build-container:0.9:BUILD_ARGS_FILE|
|build-image-index| Add built image into an OCI image index| false| build-image-index:0.3:ALWAYS_BUILD_INDEX|
|buildah-format| The format for the resulting image's mediaType. Valid values are oci or docker.| docker| build-container:0.9:BUILDAH_FORMAT ; build-image-index:0.3:BUILDAH_FORMAT|
|dockerfile| Path to the Dockerfile inside the context specified by parameter path-context| Dockerfile| build-container:0.9:DOCKERFILE|
|enable-cache-proxy| Enable cache proxy configuration| false| init:0.4:enable-cache-proxy|
|enable-package-registry-proxy| Use the package registry proxy when prefetching dependencies| true| prefetch-dependencies:0.3:enable-package-registry-proxy|
|git-url| Source Repository URL| None| clone-repository:0.1:url|
|hermetic| Execute the build with network isolation| false| build-container:0.9:HERMETIC|
|image-expires-after| Image tag expiration time, time values could be something like 1h, 2d, 3w for hours, days, and weeks, respectively.| | clone-repository:0.1:ociArtifactExpiresAfter ; prefetch-dependencies:0.3:ociArtifactExpiresAfter ; build-container:0.9:IMAGE_EXPIRES_AFTER|
|output-image| Fully Qualified Output Image| None| clone-repository:0.1:ociStorage ; prefetch-dependencies:0.3:ociStorage ; build-container:0.9:IMAGE ; build-image-index:0.3:IMAGE|
|path-context| Path to the source code of an application's component from where to build image.| .| build-container:0.9:CONTEXT|
|prefetch-input| Build dependencies to be prefetched| | prefetch-dependencies:0.3:input ; build-container:0.9:PREFETCH_INPUT|
|privileged-nested| Whether to enable privileged mode, should be used only with remote VMs| false| build-container:0.9:PRIVILEGED_NESTED|
|revision| Revision of the Source Repository| | clone-repository:0.1:revision|
|skip-checks| Skip checks against built image| false| |

## Available params from tasks
### build-image-index-min:0.3 task parameters
|name|description|default value|already set by|
|---|---|---|---|
|ALWAYS_BUILD_INDEX| Build an image index even if IMAGES is of length 1. Default true. If the image index generation is skipped, the task will forward values for params.IMAGES[0] to results.IMAGE_*. In order to properly set all results, use the repository:tag@sha256:digest format for the IMAGES parameter.| true| '$(params.build-image-index)'|
|BUILDAH_FORMAT| The format for the resulting image's mediaType. Valid values are oci (default) or docker.| oci| '$(params.buildah-format)'|
|IMAGE| The target image and tag where the image will be pushed to.| None| '$(params.output-image)'|
|IMAGES| List of Image Manifests to be referenced by the Image Index| None| '['$(tasks.build-container.results.IMAGE_URL)@$(tasks.build-container.results.IMAGE_DIGEST)']'|
|SBOM_SKIP_VALIDATION| Flag to enable or disable SBOM validation before save. Validation is optional - use this if you are experiencing performance issues.| false| |
|STORAGE_DRIVER| Storage driver to configure for buildah| vfs| |
|TLSVERIFY| Verify the TLS on the registry endpoint (for push/pull to a non-TLS registry)| true| |
|caTrustConfigMapKey| The name of the key in the ConfigMap that contains the CA bundle data| ca-bundle.crt| |
|caTrustConfigMapName| The name of the ConfigMap to read CA bundle data from| trusted-ca| |
### buildah-oci-ta-min:0.9 task parameters
|name|description|default value|already set by|
|---|---|---|---|
|ACTIVATION_KEY| Name of secret which contains subscription activation key| activation-key| |
|ADDITIONAL_BASE_IMAGES| Additional base image references to include to the SBOM. Array of image_reference_with_digest strings| []| |
|ADDITIONAL_SECRET| Name of a secret which will be made available to the build with 'buildah build --secret' at /run/secrets/$ADDITIONAL_SECRET| does-not-exist| |
|ADD_CAPABILITIES| Comma separated list of extra capabilities to add when running 'buildah build'| ""| |
|ANNOTATIONS| Additional key=value annotations that should be applied to the image| []| |
|ANNOTATIONS_FILE| Path to a file with additional key=value annotations that should be applied to the image| ""| |
|BUILDAH_FORMAT| The format for the resulting image's mediaType. Valid values are oci (default) or docker.| oci| '$(params.buildah-format)'|
|BUILD_ARGS| Array of --build-arg values ("arg=value" strings)| []| '['$(params.build-args[*])']'|
|BUILD_ARGS_FILE| Path to a file with build arguments, see https://www.mankier.com/1/buildah-build#--build-arg-file| ""| '$(params.build-args-file)'|
|BUILD_TIMESTAMP| Defines the single build time for all buildah builds in seconds since UNIX epoch. Conflicts with SOURCE_DATE_EPOCH.| ""| |
|CACHI2_ARTIFACT| The Trusted Artifact URI pointing to the artifact with the prefetched dependencies.| ""| '$(tasks.prefetch-dependencies.results.CACHI2_ARTIFACT)'|
|COMMIT_SHA| The image is built from this commit.| ""| '$(tasks.clone-repository.results.commit)'|
|CONTEXT| Path to the directory to use as context.| .| '$(params.path-context)'|
|CONTEXTUALIZE_SBOM| Determines if SBOM will be contextualized.| true| |
|DOCKERFILE| Path to the Dockerfile to build.| ./Dockerfile| '$(params.dockerfile)'|
|ENTITLEMENT_SECRET| Name of secret which contains the entitlement certificates| etc-pki-entitlement| |
|ENV_VARS| Array of --env values ("env=value" strings)| []| |
|HERMETIC| Determines if build will be executed without network access.| false| '$(params.hermetic)'|
|HTTP_PROXY| HTTP/HTTPS proxy to use for the buildah pull and build operations. Will not be passed through to the container during the build process.| ""| '$(tasks.init.results.http-proxy)'|
|ICM_KEEP_COMPAT_LOCATION| Whether to keep compatibility location at /root/buildinfo/ for ICM injection| true| |
|IMAGE| Reference of the image buildah will produce.| None| '$(params.output-image)'|
|IMAGE_EXPIRES_AFTER| Delete image tag after specified time. Empty means to keep the image tag. Time values could be something like 1h, 2d, 3w for hours, days, and weeks, respectively.| ""| '$(params.image-expires-after)'|
|INHERIT_BASE_IMAGE_LABELS| Determines if the image inherits the base image labels.| true| |
|LABELS| Additional key=value labels that should be applied to the image| []| |
|NO_PROXY| Comma separated list of hosts or domains which should bypass the HTTP/HTTPS proxy.| ""| '$(tasks.init.results.no-proxy)'|
|OMIT_HISTORY| Omit build history information from the resulting image. Improves reproducibility by excluding timestamps and layer metadata.| false| |
|PREFETCH_INPUT| In case it is not empty, the prefetched content should be made available to the build.| ""| '$(params.prefetch-input)'|
|PRIVILEGED_NESTED| Whether to enable privileged mode, should be used only with remote VMs| false| '$(params.privileged-nested)'|
|PROXY_CA_TRUST_CONFIG_MAP_KEY| The name of the key in the ConfigMap that contains the proxy CA bundle data.| ca-bundle.crt| |
|PROXY_CA_TRUST_CONFIG_MAP_NAME| The name of the ConfigMap to read proxy CA bundle data from.| caching-ca-bundle| |
|REWRITE_TIMESTAMP| Clamp mtime of all files to at most SOURCE_DATE_EPOCH. Does nothing if SOURCE_DATE_EPOCH is not defined.| false| |
|SBOM_SKIP_VALIDATION| Flag to enable or disable SBOM validation before save. Validation is optional - use this if you are experiencing performance issues.| true| |
|SBOM_SOURCE_SCAN_ENABLED| Flag to enable or disable SBOM generation from source code. The scanner of the source code is enabled only for non-hermetic builds and can be disabled if the SBOM_SYFT_SELECT_CATALOGERS can't turn off catalogers that cause false positives on source code scanning.| true| |
|SBOM_SYFT_SELECT_CATALOGERS| Extra option to customize Syft's default catalogers when generating SBOMs. The value corresponds to Syft's CLI flag --select-catalogers. The details about available catalogers can be found here: https://github.com/anchore/syft/wiki/Package-Cataloger-Selection| ""| |
|SBOM_TYPE| Select the SBOM format to generate. Valid values: spdx, cyclonedx. Note: the SBOM from the prefetch task - if there is one - must be in the same format.| spdx| |
|SKIP_INJECTIONS| Don't inject a content-sets.json or a labels.json file. This requires that the canonical Containerfile takes care of this itself.| false| |
|SKIP_SBOM_GENERATION| Skip SBOM-related operations. This will likely cause EC policies to fail if enabled| false| |
|SKIP_UNUSED_STAGES| Whether to skip stages in Containerfile that seem unused by subsequent stages| true| |
|SOURCE_ARTIFACT| The Trusted Artifact URI pointing to the artifact with the application source code.| None| '$(tasks.prefetch-dependencies.results.SOURCE_ARTIFACT)'|
|SOURCE_DATE_EPOCH| Timestamp in seconds since Unix epoch for reproducible builds. Sets image created time and SOURCE_DATE_EPOCH build arg. Conflicts with BUILD_TIMESTAMP.| ""| |
|SOURCE_URL| The image is built from this URL.| ""| '$(tasks.clone-repository.results.url)'|
|SQUASH| Squash all new and previous layers added as a part of this build, as per --squash| false| |
|STORAGE_DRIVER| Storage driver to configure for buildah| overlay| |
|TARGET_STAGE| Target stage in Dockerfile to build. If not specified, the Dockerfile is processed entirely to (and including) its last stage.| ""| |
|TLSVERIFY| Verify the TLS on the registry endpoint (for push/pull to a non-TLS registry)| true| |
|WORKINGDIR_MOUNT| Mount the current working directory into the build using --volume $PWD:/$WORKINGDIR_MOUNT. Note that the $PWD will be the context directory for the build (see the CONTEXT param).| ""| |
|YUM_REPOS_D_FETCHED| Path in source workspace where dynamically-fetched repos are present| fetched.repos.d| |
|YUM_REPOS_D_SRC| Path in the git repository in which yum repository files are stored| repos.d| |
|YUM_REPOS_D_TARGET| Target path on the container in which yum repository files should be made available| /etc/yum.repos.d| |
|caTrustConfigMapKey| The name of the key in the ConfigMap that contains the CA bundle data.| ca-bundle.crt| |
|caTrustConfigMapName| The name of the ConfigMap to read CA bundle data from.| trusted-ca| |
### clamav-scan-min:0.3 task parameters
|name|description|default value|already set by|
|---|---|---|---|
|ca-trust-config-map-key| The name of the key in the ConfigMap that contains the CA bundle data.| ca-bundle.crt| |
|ca-trust-config-map-name| The name of the ConfigMap to read CA bundle data from.| trusted-ca| |
|clamd-max-threads| Maximum number of threads clamd runs.| 8| |
|docker-auth| unused| ""| |
|image-arch| Image arch.| ""| |
|image-digest| Image digest to scan.| None| '$(tasks.build-image-index.results.IMAGE_DIGEST)'|
|image-url| Image URL.| None| '$(tasks.build-image-index.results.IMAGE_URL)'|
|skip-upload| If true, skips uploading the results to the image registry. Useful for read-only tests.| false| |
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
### git-clone-oci-ta-min:0.1 task parameters
|name|description|default value|already set by|
|---|---|---|---|
|caTrustConfigMapKey| The name of the key in the ConfigMap that contains the CA bundle data.| ca-bundle.crt| |
|caTrustConfigMapName| The name of the ConfigMap to read CA bundle data from.| trusted-ca| |
|depth| Perform a shallow clone, fetching only the most recent N commits.| 1| |
|enableSymlinkCheck| Check symlinks in the repo. If they're pointing outside of the repo, the build will fail. | true| |
|fetchTags| Fetch all tags for the repo.| false| |
|httpProxy| HTTP proxy server for non-SSL requests.| ""| |
|httpsProxy| HTTPS proxy server for SSL requests.| ""| |
|mergeSourceDepth| Perform a shallow fetch of the target branch, fetching only the most recent N commits. If empty, fetches the full history of the target branch. | ""| |
|mergeSourceRepoUrl| URL of the repository to fetch the target branch from when mergeTargetBranch is true. If empty, uses the same repository (origin). This allows merging a branch from a different repository. | ""| |
|mergeTargetBranch| Set to "true" to merge the targetBranch into the checked-out revision.| false| |
|noProxy| Opt out of proxying HTTP/HTTPS requests.| ""| |
|ociArtifactExpiresAfter| Expiration date for the trusted artifacts created in the OCI repository. An empty string means the artifacts do not expire.| ""| '$(params.image-expires-after)'|
|ociStorage| The OCI repository where the Trusted Artifacts are stored.| None| '$(params.output-image).git'|
|refspec| Refspec to fetch before checking out revision.| ""| |
|revision| Revision to checkout. (branch, tag, sha, ref, etc...)| ""| '$(params.revision)'|
|shortCommitLength| Length of short commit SHA| 7| |
|sparseCheckoutDirectories| Define the directory patterns to match or exclude when performing a sparse checkout.| ""| |
|sslVerify| Set the `http.sslVerify` global git config. Setting this to `false` is not advised unless you are sure that you trust your git remote.| true| |
|submodulePaths| Comma-separated list of specific submodule paths to initialize and fetch. Only submodules in the specified directories and their subdirectories will be fetched. Empty string fetches all submodules. Parameter "submodules" must be set to "true" to make this parameter applicable. | ""| |
|submodules| Initialize and fetch git submodules.| true| |
|targetBranch| The target branch to merge into the revision (if mergeTargetBranch is true).| main| |
|url| Repository URL to clone from.| None| '$(params.git-url)'|
|userHome| Absolute path to the user's home directory. Set this explicitly if you are running the image as a non-root user. | /tekton/home| |
|verbose| Log the commands that are executed during `git-clone`'s operation.| false| |
### init:0.4 task parameters
|name|description|default value|already set by|
|---|---|---|---|
|enable-cache-proxy| Enable cache proxy configuration| false| '$(params.enable-cache-proxy)'|
### prefetch-dependencies-oci-ta-min:0.3 task parameters
|name|description|default value|already set by|
|---|---|---|---|
|ACTIVATION_KEY| Name of secret which contains subscription activation key| activation-key| |
|SERVICE_CA_TRUST_CONFIG_MAP_KEY| The name of the key in the ConfigMap that contains the service CA bundle data. Used to verify TLS connections to in-cluster services such as the package registry proxy.| service-ca.crt| |
|SERVICE_CA_TRUST_CONFIG_MAP_NAME| The name of the ConfigMap to read service CA bundle data from. Used to verify TLS connections to in-cluster services such as the package registry proxy.| openshift-service-ca.crt| |
|SOURCE_ARTIFACT| The Trusted Artifact URI pointing to the artifact with the application source code.| None| '$(tasks.clone-repository.results.SOURCE_ARTIFACT)'|
|caTrustConfigMapKey| The name of the key in the ConfigMap that contains the CA bundle data.| ca-bundle.crt| |
|caTrustConfigMapName| The name of the ConfigMap to read CA bundle data from.| trusted-ca| |
|config-file-content| Pass configuration to the prefetch tool. Note this needs to be passed as a YAML-formatted config dump, not as a file path! | ""| |
|enable-package-registry-proxy| Use the package registry proxy when prefetching dependencies| true| '$(params.enable-package-registry-proxy)'|
|input| Configures project packages that will have their dependencies prefetched.| None| '$(params.prefetch-input)'|
|log-level| Set the logging level (debug, info, warn, error, fatal).| debug| |
|mode| Control how input requirement violations are handled: strict (errors) or permissive (warnings).| strict| |
|ociArtifactExpiresAfter| Expiration date for the trusted artifacts created in the OCI repository. An empty string means the artifacts do not expire.| ""| '$(params.image-expires-after)'|
|ociStorage| The OCI repository where the Trusted Artifacts are stored.| None| '$(params.output-image).prefetch'|
|sbom-type| Select the SBOM format to generate. Valid values: spdx, cyclonedx.| spdx| |
### rpms-signature-scan:0.2 task parameters
|name|description|default value|already set by|
|---|---|---|---|
|ca-trust-config-map-key| The name of the key in the ConfigMap that contains the CA bundle data.| ca-bundle.crt| |
|ca-trust-config-map-name| The name of the ConfigMap to read CA bundle data from.| trusted-ca| |
|image-digest| Image digest to scan| None| '$(tasks.build-image-index.results.IMAGE_DIGEST)'|
|image-url| Image URL| None| '$(tasks.build-image-index.results.IMAGE_URL)'|
|workdir| Directory that will be used for storing temporary files produced by this task. | /tmp| |
### sast-shell-check-oci-ta-min:0.1 task parameters
|name|description|default value|already set by|
|---|---|---|---|
|CACHI2_ARTIFACT| The Trusted Artifact URI pointing to the artifact with the prefetched dependencies.| ""| '$(tasks.prefetch-dependencies.results.CACHI2_ARTIFACT)'|
|IMP_FINDINGS_ONLY| Whether to include important findings only| true| |
|KFP_GIT_URL| Known False Positives (KFP) git URL (optionally taking a revision delimited by \#). Defaults to "SITE_DEFAULT", which means the default value "https://gitlab.cee.redhat.com/osh/known-false-positives.git" for internal Konflux instance and empty string for external Konflux instance. If set to an empty string, the KFP filtering is disabled.| SITE_DEFAULT| |
|PROJECT_NAME| Name of the scanned project, used to find path exclusions. By default, the Konflux component name will be used.| ""| |
|RECORD_EXCLUDED| Whether to record the excluded findings (default to false). If `true`, the excluded findings will be stored in `excluded-findings.json`. | false| |
|SOURCE_ARTIFACT| The Trusted Artifact URI pointing to the artifact with the application source code.| None| '$(tasks.prefetch-dependencies.results.SOURCE_ARTIFACT)'|
|TARGET_DIRS| Target directories in component's source code. Multiple values should be separated with commas.| .| |
|caTrustConfigMapKey| The name of the key in the ConfigMap that contains the CA bundle data.| ca-bundle.crt| |
|caTrustConfigMapName| The name of the ConfigMap to read CA bundle data from.| trusted-ca| |
|image-digest| Image digest to report findings for.| ""| '$(tasks.build-image-index.results.IMAGE_DIGEST)'|
|image-url| Image URL.| ""| '$(tasks.build-image-index.results.IMAGE_URL)'|
### sast-unicode-check-oci-ta-min:0.4 task parameters
|name|description|default value|already set by|
|---|---|---|---|
|CACHI2_ARTIFACT| The Trusted Artifact URI pointing to the artifact with the prefetched dependencies.| ""| '$(tasks.prefetch-dependencies.results.CACHI2_ARTIFACT)'|
|FIND_UNICODE_CONTROL_ARGS| arguments for find-unicode-control command.| -p bidi -v -d -t| |
|KFP_GIT_URL| Known False Positives (KFP) git URL (optionally taking a revision delimited by \#). Defaults to "SITE_DEFAULT", which means the default value "https://gitlab.cee.redhat.com/osh/known-false-positives.git" for internal Konflux instance and empty string for external Konflux instance. If set to an empty string, the KFP filtering is disabled.| SITE_DEFAULT| |
|PROJECT_NAME| Name of the scanned project, used to find path exclusions. By default, the Konflux component name will be used.| ""| |
|RECORD_EXCLUDED| Whether to record the excluded findings (defaults to false). If `true`, the excluded findings will be stored in `excluded-findings.json`. | false| |
|SOURCE_ARTIFACT| The Trusted Artifact URI pointing to the artifact with the application source code.| None| '$(tasks.prefetch-dependencies.results.SOURCE_ARTIFACT)'|
|TARGET_DIRS| Target directories in component's source code. Multiple values should be separated with commas.| .| |
|caTrustConfigMapKey| The name of the key in the ConfigMap that contains the CA bundle data.| ca-bundle.crt| |
|caTrustConfigMapName| The name of the ConfigMap to read CA bundle data from.| trusted-ca| |
|image-digest| Image digest used for ORAS upload.| None| '$(tasks.build-image-index.results.IMAGE_DIGEST)'|
|image-url| Image URL used for ORAS upload.| None| '$(tasks.build-image-index.results.IMAGE_URL)'|
### tpa-scan:0.1 task parameters
|name|description|default value|already set by|
|---|---|---|---|
|ca-trust-config-map-key| The name of the key in the ConfigMap that contains the CA bundle data.| ca-bundle.crt| |
|ca-trust-config-map-name| The name of the ConfigMap to read CA bundle data from.| trusted-ca| |
|image-digest| Image digest to scan.| None| '$(tasks.build-image-index.results.IMAGE_DIGEST)'|
|image-platform| The platform which will be scanned by this task.| ""| |
|image-url| Image URL.| None| '$(tasks.build-image-index.results.IMAGE_URL)'|
|skip-oci-attach-report| If true, skips uploading the results to the image registry. Useful for read-only tests.| false| |
|tpa-url| The url of the TPA instance which will be used for scanning.| https://exhort.stage.devshift.net/api/v5/analysis| |

## Results
|name|description|value|
|---|---|---|
|CHAINS-GIT_COMMIT| |$(tasks.clone-repository.results.commit)|
|CHAINS-GIT_URL| |$(tasks.clone-repository.results.url)|
|IMAGE_DIGEST| |$(tasks.build-image-index.results.IMAGE_DIGEST)|
|IMAGE_URL| |$(tasks.build-image-index.results.IMAGE_URL)|
## Available results from tasks
### build-image-index-min:0.3 task results
|name|description|used in params (taskname:taskrefversion:taskparam)
|---|---|---|
|IMAGES| List of all referenced image manifests| |
|IMAGE_DIGEST| Digest of the image just built| deprecated-base-image-check:0.5:IMAGE_DIGEST ; clamav-scan:0.3:image-digest ; sast-shell-check:0.1:image-digest ; sast-unicode-check:0.4:image-digest ; rpms-signature-scan:0.2:image-digest ; tpa-scan:0.1:image-digest|
|IMAGE_REF| Image reference of the built image containing both the repository and the digest| |
|IMAGE_URL| Image repository and tag where the built image was pushed| deprecated-base-image-check:0.5:IMAGE_URL ; clamav-scan:0.3:image-url ; sast-shell-check:0.1:image-url ; sast-unicode-check:0.4:image-url ; rpms-signature-scan:0.2:image-url ; tpa-scan:0.1:image-url|
|SBOM_BLOB_URL| Reference of SBOM blob digest to enable digest-based verification from provenance| |
### buildah-oci-ta-min:0.9 task results
|name|description|used in params (taskname:taskrefversion:taskparam)
|---|---|---|
|IMAGE_DIGEST| Digest of the image just built| |
|IMAGE_REF| Image reference of the built image| |
|IMAGE_URL| Image repository and tag where the built image was pushed| build-image-index:0.3:IMAGES|
|SBOM_BLOB_URL| Reference of SBOM blob digest to enable digest-based verification from provenance| |
### clamav-scan-min:0.3 task results
|name|description|used in params (taskname:taskrefversion:taskparam)
|---|---|---|
|IMAGES_PROCESSED| Images processed in the task.| |
|TEST_OUTPUT| Tekton task test output.| |
### deprecated-image-check:0.5 task results
|name|description|used in params (taskname:taskrefversion:taskparam)
|---|---|---|
|IMAGES_PROCESSED| Images processed in the task.| |
|TEST_OUTPUT| Tekton task test output.| |
### git-clone-oci-ta-min:0.1 task results
|name|description|used in params (taskname:taskrefversion:taskparam)
|---|---|---|
|CHAINS-GIT_COMMIT| The precise commit SHA that was fetched by this Task. This result uses Chains type hinting to include in the provenance.| |
|CHAINS-GIT_URL| The precise URL that was fetched by this Task. This result uses Chains type hinting to include in the provenance.| |
|SOURCE_ARTIFACT| The Trusted Artifact URI pointing to the artifact with the application source code.| prefetch-dependencies:0.3:SOURCE_ARTIFACT|
|commit| The precise commit SHA that was fetched by this Task.| build-container:0.9:COMMIT_SHA|
|commit-timestamp| The commit timestamp of the checkout| |
|merged_sha| The SHA of the commit after merging the target branch (if the param mergeTargetBranch is true).| |
|short-commit| The commit SHA that was fetched by this Task limited to params.shortCommitLength number of characters| |
|url| The precise URL that was fetched by this Task.| build-container:0.9:SOURCE_URL|
### init:0.4 task results
|name|description|used in params (taskname:taskrefversion:taskparam)
|---|---|---|
|http-proxy| HTTP proxy URL for cache proxy (when enable-cache-proxy is true)| build-container:0.9:HTTP_PROXY|
|no-proxy| NO_PROXY value for cache proxy (when enable-cache-proxy is true)| build-container:0.9:NO_PROXY|
### prefetch-dependencies-oci-ta-min:0.3 task results
|name|description|used in params (taskname:taskrefversion:taskparam)
|---|---|---|
|CACHI2_ARTIFACT| The Trusted Artifact URI pointing to the artifact with the prefetched dependencies.| build-container:0.9:CACHI2_ARTIFACT ; sast-shell-check:0.1:CACHI2_ARTIFACT ; sast-unicode-check:0.4:CACHI2_ARTIFACT|
|SOURCE_ARTIFACT| The Trusted Artifact URI pointing to the artifact with the application source code.| build-container:0.9:SOURCE_ARTIFACT ; sast-shell-check:0.1:SOURCE_ARTIFACT ; sast-unicode-check:0.4:SOURCE_ARTIFACT|
### rpms-signature-scan:0.2 task results
|name|description|used in params (taskname:taskrefversion:taskparam)
|---|---|---|
|IMAGES_PROCESSED| Images processed in the task.| |
|RPMS_DATA| Information about signed and unsigned RPMs| |
|TEST_OUTPUT| Tekton task test output.| |
### sast-shell-check-oci-ta-min:0.1 task results
|name|description|used in params (taskname:taskrefversion:taskparam)
|---|---|---|
|TEST_OUTPUT| Tekton task test output.| |
### sast-unicode-check-oci-ta-min:0.4 task results
|name|description|used in params (taskname:taskrefversion:taskparam)
|---|---|---|
|TEST_OUTPUT| Tekton task test output.| |
### tpa-scan:0.1 task results
|name|description|used in params (taskname:taskrefversion:taskparam)
|---|---|---|
|IMAGES_PROCESSED| Images processed in the task.| |
|REPORTS| Mapping of image digests to report digests| |
|SCAN_OUTPUT| TPA scan result.| |
|TEST_OUTPUT| Tekton task test output.| |

## Workspaces
|name|description|optional|used in tasks
|---|---|---|---|
|git-auth| |True| clone-repository:0.1:basic-auth ; prefetch-dependencies:0.3:git-basic-auth|
|netrc| |True| prefetch-dependencies:0.3:netrc|
## Available workspaces from tasks
### git-clone-oci-ta-min:0.1 task workspaces
|name|description|optional|workspace from pipeline
|---|---|---|---|
|basic-auth| A Workspace containing a .gitconfig and .git-credentials file or username and password. These will be copied to the user's home before any git commands are run. Any other files in this Workspace are ignored. It is strongly recommended to use ssh-directory over basic-auth whenever possible and to bind a Secret to this Workspace over other volume types. | True| git-auth|
|ssh-directory| A .ssh directory with private key, known_hosts, config, etc. Copied to the user's home before git commands are executed. Used to authenticate with the git remote when performing the clone. Binding a Secret to this Workspace is strongly recommended over other volume types. | True| |
### prefetch-dependencies-oci-ta-min:0.3 task workspaces
|name|description|optional|workspace from pipeline
|---|---|---|---|
|git-basic-auth| A Workspace containing a .gitconfig and .git-credentials file or username and password. These will be copied to the user's home before prefetch is run. Any other files in this Workspace are ignored. It is strongly recommended to bind a Secret to this Workspace over other volume types. | True| git-auth|
|netrc| Workspace containing a .netrc file. Prefetch will use the credentials in this file when performing http(s) requests. | True| netrc|
