# "ko-build-oci-ta pipeline"
This pipeline is ideal for building container images while maintaining trust after pipeline customization.

_Uses `ko` to create a container image leveraging [trusted artifacts](https://konflux-ci.dev/architecture/ADR/0036-trusted-artifacts.html). It also optionally creates a source image and runs some build-time tests. Information is shared between tasks using OCI artifacts instead of PVCs. EC will pass the [`trusted_task.trusted`](https://conforma.dev/docs/policy/packages/release_trusted_task.html#trusted_task__trusted) policy as long as all data used to build the artifact is generated from trusted tasks.
This pipeline is pushed as a Tekton bundle to [quay.io](https://quay.io/repository/konflux-ci/tekton-catalog/pipeline-ko-build-oci-ta?tab=tags)_

## Parameters
|name|description|default value|used in (taskname:taskrefversion:taskparam)|
|---|---|---|---|
|build-source-image| Build a source image.| false| |
|default-base-image| Default base image for ko| | build-container:0.1:KO_DEFAULTBASEIMAGE|
|git-url| Source Repository URL| None| clone-repository:0.1:url|
|image-expires-after| Image tag expiration time, time values could be something like 1h, 2d, 3w for hours, days, and weeks, respectively.| | clone-repository:0.1:ociArtifactExpiresAfter ; prefetch-dependencies:0.2:ociArtifactExpiresAfter ; build-container:0.1:IMAGE_EXPIRES_AFTER ; build-image-index:0.1:IMAGE_EXPIRES_AFTER|
|import-path| Import path to build| | build-container:0.1:IMPORT_PATH|
|ko-docker-repo| Setting for KO_DOCKER_REPO| | build-container:0.1:KO_DOCKER_REPO|
|output-image| Fully Qualified Output Image| None| init:0.2:image-url ; clone-repository:0.1:ociStorage ; prefetch-dependencies:0.2:ociStorage ; build-image-index:0.1:IMAGE|
|pr-tag| PR tag to use on image| pr-tag| build-container:0.1:TAG|
|prefetch-input| Build dependencies to be prefetched| | prefetch-dependencies:0.2:input|
|preprocessing-script| Preprocessing script for source code| | |
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
### build-image-index:0.1 task parameters
|name|description|default value|already set by|
|---|---|---|---|
|ALWAYS_BUILD_INDEX| Build an image index even if IMAGES is of length 1. Default true. If the image index generation is skipped, the task will forward values for params.IMAGES[0] to results.IMAGE_*. In order to properly set all results, use the repository:tag@sha256:digest format for the IMAGES parameter.| true| 'true'|
|BUILDAH_FORMAT| The format for the resulting image's mediaType. Valid values are oci (default) or docker.| oci| 'docker'|
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
### git-clone-oci-ta:0.1 task parameters
|name|description|default value|already set by|
|---|---|---|---|
|caTrustConfigMapKey| The name of the key in the ConfigMap that contains the CA bundle data.| ca-bundle.crt| |
|caTrustConfigMapName| The name of the ConfigMap to read CA bundle data from.| trusted-ca| |
|depth| Perform a shallow clone, fetching only the most recent N commits.| 1| |
|enableSymlinkCheck| Check symlinks in the repo. If they're pointing outside of the repo, the build will fail. | true| |
|fetchTags| Fetch all tags for the repo.| false| |
|httpProxy| HTTP proxy server for non-SSL requests.| ""| |
|httpsProxy| HTTPS proxy server for SSL requests.| ""| |
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
### init:0.2 task parameters
|name|description|default value|already set by|
|---|---|---|---|
|image-url| Image URL for build by PipelineRun| None| '$(params.output-image)'|
|rebuild| Rebuild the image if exists| false| '$(params.rebuild)'|
|skip-checks| Skip checks against built image| false| '$(params.skip-checks)'|
### ko-oci-ta:0.1 task parameters
|name|description|default value|already set by|
|---|---|---|---|
|COMMIT_SHA| The image is built from this commit.| ""| '$(tasks.clone-repository.results.commit)'|
|IMAGE_EXPIRES_AFTER| Delete image tag after specified time. Empty means to keep the image tag. Time values could be something like 1h, 2d, 3w for hours, days, and weeks, respectively.| ""| '$(params.image-expires-after)'|
|IMAGE_NAMING_STRATEGY| One of --base-import-paths, --bare, or --preserve-import-paths| --base-import-paths| |
|IMPORT_PATH| import path of package main| .| '$(params.import-path)'|
|KO_DEFAULTBASEIMAGE| base image for ko build| ""| '$(params.default-base-image)'|
|KO_DOCKER_REPO| Container repository where to push images built with ko| ""| '$(params.ko-docker-repo)'|
|SOURCE_ARTIFACT| The Trusted Artifact URI pointing to the artifact with the application source code.| None| '$(tasks.prefetch-dependencies.results.SOURCE_ARTIFACT)'|
|TAG| Tag of PR to add to image| None| '$(params.pr-tag)'|
|caTrustConfigMapKey| The name of the key in the ConfigMap that contains the CA bundle data.| ca-bundle.crt| |
|caTrustConfigMapName| The name of the ConfigMap to read CA bundle data from.| trusted-ca| |
### prefetch-dependencies-oci-ta:0.2 task parameters
|name|description|default value|already set by|
|---|---|---|---|
|ACTIVATION_KEY| Name of secret which contains subscription activation key| activation-key| |
|SOURCE_ARTIFACT| The Trusted Artifact URI pointing to the artifact with the application source code.| None| '$(tasks.clone-repository.results.SOURCE_ARTIFACT)'|
|caTrustConfigMapKey| The name of the key in the ConfigMap that contains the CA bundle data.| ca-bundle.crt| |
|caTrustConfigMapName| The name of the ConfigMap to read CA bundle data from.| trusted-ca| |
|config-file-content| Pass configuration to the prefetch tool. Note this needs to be passed as a YAML-formatted config dump, not as a file path! | ""| |
|dev-package-managers| Enable in-development package managers. WARNING: the behavior may change at any time without notice. Use at your own risk. | false| |
|input| Configures project packages that will have their dependencies prefetched.| None| '$(params.prefetch-input)'|
|log-level| Set prefetch tool log level (debug, info, warning, error)| info| |
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
### sast-shell-check-oci-ta:0.1 task parameters
|name|description|default value|already set by|
|---|---|---|---|
|CACHI2_ARTIFACT| The Trusted Artifact URI pointing to the artifact with the prefetched dependencies.| ""| |
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
### sast-snyk-check-oci-ta:0.4 task parameters
|name|description|default value|already set by|
|---|---|---|---|
|ARGS| Append arguments.| ""| |
|CACHI2_ARTIFACT| The Trusted Artifact URI pointing to the artifact with the prefetched dependencies.| ""| |
|IGNORE_FILE_PATHS| Directories or files to be excluded from Snyk scan (Comma-separated). Useful to split the directories of a git repo across multiple components.| ""| |
|IMP_FINDINGS_ONLY| Report only important findings. Default is true. To report all findings, specify "false"| true| |
|KFP_GIT_URL| Known False Positives (KFP) git URL (optionally taking a revision delimited by \#). Defaults to "SITE_DEFAULT", which means the default value "https://gitlab.cee.redhat.com/osh/known-false-positives.git" for internal Konflux instance and empty string for external Konflux instance. If set to an empty string, the KFP filtering is disabled.| SITE_DEFAULT| |
|PROJECT_NAME| Name of the scanned project, used to find path exclusions. By default, the Konflux component name will be used.| ""| |
|RECORD_EXCLUDED| Write excluded records in file. Useful for auditing (defaults to false).| false| |
|SNYK_SECRET| Name of secret which contains Snyk token.| snyk-secret| |
|SOURCE_ARTIFACT| The Trusted Artifact URI pointing to the artifact with the application source code.| None| '$(tasks.prefetch-dependencies.results.SOURCE_ARTIFACT)'|
|TARGET_DIRS| Target directories in component's source code. Multiple values should be separated with commas.| .| |
|caTrustConfigMapKey| The name of the key in the ConfigMap that contains the CA bundle data.| ca-bundle.crt| |
|caTrustConfigMapName| The name of the ConfigMap to read CA bundle data from.| trusted-ca| |
|image-digest| Digest of the image to scan.| None| '$(tasks.build-image-index.results.IMAGE_DIGEST)'|
|image-url| Image URL.| None| '$(tasks.build-image-index.results.IMAGE_URL)'|
### sast-unicode-check-oci-ta:0.3 task parameters
|name|description|default value|already set by|
|---|---|---|---|
|CACHI2_ARTIFACT| The Trusted Artifact URI pointing to the artifact with the prefetched dependencies.| ""| |
|FIND_UNICODE_CONTROL_ARGS| arguments for find-unicode-control command.| -p bidi -v -d -t| |
|FIND_UNICODE_CONTROL_GIT_URL| URL from repository to find unicode control.| https://github.com/siddhesh/find-unicode-control.git#c2accbfbba7553a8bc1ebd97089ae08ad8347e58| |
|KFP_GIT_URL| Known False Positives (KFP) git URL (optionally taking a revision delimited by \#). Defaults to "SITE_DEFAULT", which means the default value "https://gitlab.cee.redhat.com/osh/known-false-positives.git" for internal Konflux instance and empty string for external Konflux instance. If set to an empty string, the KFP filtering is disabled.| SITE_DEFAULT| |
|PROJECT_NAME| Name of the scanned project, used to find path exclusions. By default, the Konflux component name will be used.| ""| |
|RECORD_EXCLUDED| Whether to record the excluded findings (defaults to false). If `true`, the excluded findings will be stored in `excluded-findings.json`. | false| |
|SOURCE_ARTIFACT| The Trusted Artifact URI pointing to the artifact with the application source code.| None| '$(tasks.prefetch-dependencies.results.SOURCE_ARTIFACT)'|
|caTrustConfigMapKey| The name of the key in the ConfigMap that contains the CA bundle data.| ca-bundle.crt| |
|caTrustConfigMapName| The name of the ConfigMap to read CA bundle data from.| trusted-ca| |
|image-digest| Image digest used for ORAS upload.| None| '$(tasks.build-image-index.results.IMAGE_DIGEST)'|
|image-url| Image URL used for ORAS upload.| None| '$(tasks.build-image-index.results.IMAGE_URL)'|
### source-build-oci-ta:0.3 task parameters
|name|description|default value|already set by|
|---|---|---|---|
|BASE_IMAGES| By default, the task inspects the SBOM of the binary image to find the base image. With this parameter, you can override that behavior and pass the base image directly. The value should be a newline-separated list of images, in the same order as the FROM instructions specified in a multistage Dockerfile.| ""| |
|BINARY_IMAGE| Binary image name with tag.| None| '$(tasks.build-image-index.results.IMAGE_URL)'|
|BINARY_IMAGE_DIGEST| Digest of the binary image.| None| '$(tasks.build-image-index.results.IMAGE_DIGEST)'|
|CACHI2_ARTIFACT| The Trusted Artifact URI pointing to the artifact with the prefetched dependencies.| ""| |
|IGNORE_UNSIGNED_IMAGE| When set to "true", source build task won't fail when source image is missing signatures (this can be used for development)| false| |
|SOURCE_ARTIFACT| The Trusted Artifact URI pointing to the artifact with the application source code.| None| '$(tasks.prefetch-dependencies.results.SOURCE_ARTIFACT)'|
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
### build-image-index:0.1 task results
|name|description|used in params (taskname:taskrefversion:taskparam)
|---|---|---|
|IMAGES| List of all referenced image manifests| |
|IMAGE_DIGEST| Digest of the image just built| build-source-image:0.3:BINARY_IMAGE_DIGEST ; deprecated-base-image-check:0.5:IMAGE_DIGEST ; clair-scan:0.3:image-digest ; sast-snyk-check:0.4:image-digest ; clamav-scan:0.3:image-digest ; sast-shell-check:0.1:image-digest ; sast-unicode-check:0.3:image-digest ; apply-tags:0.2:IMAGE_DIGEST ; rpms-signature-scan:0.2:image-digest|
|IMAGE_REF| Image reference of the built image containing both the repository and the digest| |
|IMAGE_URL| Image repository and tag where the built image was pushed| build-source-image:0.3:BINARY_IMAGE ; deprecated-base-image-check:0.5:IMAGE_URL ; clair-scan:0.3:image-url ; ecosystem-cert-preflight-checks:0.2:image-url ; sast-snyk-check:0.4:image-url ; clamav-scan:0.3:image-url ; sast-shell-check:0.1:image-url ; sast-unicode-check:0.3:image-url ; apply-tags:0.2:IMAGE_URL ; rpms-signature-scan:0.2:image-url|
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
### git-clone-oci-ta:0.1 task results
|name|description|used in params (taskname:taskrefversion:taskparam)
|---|---|---|
|CHAINS-GIT_COMMIT| The precise commit SHA that was fetched by this Task. This result uses Chains type hinting to include in the provenance.| |
|CHAINS-GIT_URL| The precise URL that was fetched by this Task. This result uses Chains type hinting to include in the provenance.| |
|SOURCE_ARTIFACT| The Trusted Artifact URI pointing to the artifact with the application source code.| prefetch-dependencies:0.2:SOURCE_ARTIFACT|
|commit| The precise commit SHA that was fetched by this Task.| build-container:0.1:COMMIT_SHA ; build-image-index:0.1:COMMIT_SHA|
|commit-timestamp| The commit timestamp of the checkout| |
|merged_sha| The SHA of the commit after merging the target branch (if the param mergeTargetBranch is true).| |
|short-commit| The commit SHA that was fetched by this Task limited to params.shortCommitLength number of characters| |
|url| The precise URL that was fetched by this Task.| |
### init:0.2 task results
|name|description|used in params (taskname:taskrefversion:taskparam)
|---|---|---|
|build| Defines if the image in param image-url should be built| |
### ko-oci-ta:0.1 task results
|name|description|used in params (taskname:taskrefversion:taskparam)
|---|---|---|
|IMAGE_DIGEST| Digest of the image just built| |
|IMAGE_REF| Image reference of the built image| |
|IMAGE_URL| Image repository and tag where the built image was pushed| build-image-index:0.1:IMAGES|
|SBOM_BLOB_URL| Reference of SBOM blob digest to enable digest-based verification from provenance| |
### prefetch-dependencies-oci-ta:0.2 task results
|name|description|used in params (taskname:taskrefversion:taskparam)
|---|---|---|
|CACHI2_ARTIFACT| The Trusted Artifact URI pointing to the artifact with the prefetched dependencies.| |
|SOURCE_ARTIFACT| The Trusted Artifact URI pointing to the artifact with the application source code.| build-container:0.1:SOURCE_ARTIFACT ; build-source-image:0.3:SOURCE_ARTIFACT ; sast-snyk-check:0.4:SOURCE_ARTIFACT ; sast-shell-check:0.1:SOURCE_ARTIFACT ; sast-unicode-check:0.3:SOURCE_ARTIFACT|
### rpms-signature-scan:0.2 task results
|name|description|used in params (taskname:taskrefversion:taskparam)
|---|---|---|
|IMAGES_PROCESSED| Images processed in the task.| |
|RPMS_DATA| Information about signed and unsigned RPMs| |
|TEST_OUTPUT| Tekton task test output.| |
### sast-shell-check-oci-ta:0.1 task results
|name|description|used in params (taskname:taskrefversion:taskparam)
|---|---|---|
|TEST_OUTPUT| Tekton task test output.| |
### sast-snyk-check-oci-ta:0.4 task results
|name|description|used in params (taskname:taskrefversion:taskparam)
|---|---|---|
|TEST_OUTPUT| Tekton task test output.| |
### sast-unicode-check-oci-ta:0.3 task results
|name|description|used in params (taskname:taskrefversion:taskparam)
|---|---|---|
|TEST_OUTPUT| Tekton task test output.| |
### source-build-oci-ta:0.3 task results
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
## Available workspaces from tasks
### git-clone-oci-ta:0.1 task workspaces
|name|description|optional|workspace from pipeline
|---|---|---|---|
|basic-auth| A Workspace containing a .gitconfig and .git-credentials file or username and password. These will be copied to the user's home before any git commands are run. Any other files in this Workspace are ignored. It is strongly recommended to use ssh-directory over basic-auth whenever possible and to bind a Secret to this Workspace over other volume types. | True| git-auth|
|ssh-directory| A .ssh directory with private key, known_hosts, config, etc. Copied to the user's home before git commands are executed. Used to authenticate with the git remote when performing the clone. Binding a Secret to this Workspace is strongly recommended over other volume types. | True| |
### prefetch-dependencies-oci-ta:0.2 task workspaces
|name|description|optional|workspace from pipeline
|---|---|---|---|
|git-basic-auth| A Workspace containing a .gitconfig and .git-credentials file or username and password. These will be copied to the user's home before prefetch is run. Any other files in this Workspace are ignored. It is strongly recommended to bind a Secret to this Workspace over other volume types. | True| git-auth|
|netrc| Workspace containing a .netrc file. Prefetch will use the credentials in this file when performing http(s) requests. | True| netrc|
