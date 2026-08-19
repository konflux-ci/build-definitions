# "package-operator-package pipeline"
Given a git repository, a reference (as in, tag or commit) and a path within the repository this pipeline will create a package-operator package.

The process of how a pko package is defined and packaged is documented [here](https://package-operator.run/docs/guides/packaging-an-application/). This task expects the package definition, will build it using `kubectl-package` and push the created package to the given OCI registry destination.

## Parameters
|name|description|default value|used in (taskname:taskparam)|
|---|---|---|---|
|build-image-index| Add built image into an OCI image index| false| build-image-index:ALWAYS_BUILD_INDEX|
|build-source-image| Build a source image.| false| |
|buildah-format| The format for the resulting image's mediaType. Valid values are oci or docker.| docker| build-image-index:BUILDAH_FORMAT|
|enable-cache-proxy| Enable cache proxy configuration| false| init:enable-cache-proxy|
|enable-package-registry-proxy| Use the package registry proxy when prefetching dependencies| true| prefetch-dependencies:enable-package-registry-proxy|
|git-url| Source Repository URL| None| clone-repository:url|
|hermetic| Execute the build with network isolation| false| |
|image-expires-after| Image tag expiration time, time values could be something like 1h, 2d, 3w for hours, days, and weeks, respectively.| | |
|labels| Additional key=value labels to add to the OCI  image.| []| build-container:LABELS|
|output-image| Fully Qualified Output Image| None| build-container:DST_URL ; build-image-index:IMAGE|
|path-context| Path to the source code of an application's component from where to build image.| .| build-container:SRC_PATH|
|prefetch-input| Build dependencies to be prefetched| | prefetch-dependencies:input|
|revision| Revision of the Source Repository| | clone-repository:revision|
|sast-target-dirs| Target directories in component's source code to scan with SAST tools. Multiple values should be separated with commas.| .| sast-snyk-check:TARGET_DIRS ; sast-shell-check:TARGET_DIRS ; sast-unicode-check:TARGET_DIRS|
|skip-checks| Skip checks against built image| false| |

## Available params from tasks
### apply-tags task parameters
|name|description|default value|already set by|
|---|---|---|---|
|ADDITIONAL_TAGS| Additional tags that will be applied to the image in the registry.| []| |
|CA_TRUST_CONFIG_MAP_KEY| The name of the key in the ConfigMap that contains the CA bundle data.| ca-bundle.crt| |
|CA_TRUST_CONFIG_MAP_NAME| The name of the ConfigMap to read CA bundle data from.| trusted-ca| |
|IMAGE_DIGEST| Image digest of the built image.| None| '$(tasks.build-image-index.results.IMAGE_DIGEST)'|
|IMAGE_URL| Image repository and tag reference of the the built image.| None| '$(tasks.build-image-index.results.IMAGE_URL)'|
|LOG_LEVEL| Log level to use in the task. See golang logrus docs for available levels.| info| |
### build-image-index task parameters
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
### clair-scan task parameters
|name|description|default value|already set by|
|---|---|---|---|
|ca-trust-config-map-key| The name of the key in the ConfigMap that contains the CA bundle data.| ca-bundle.crt| |
|ca-trust-config-map-name| The name of the ConfigMap to read CA bundle data from.| trusted-ca| |
|docker-auth| unused, should be removed in next task version.| ""| |
|image-digest| Image digest to scan.| None| '$(tasks.build-image-index.results.IMAGE_DIGEST)'|
|image-platform| The platform built by.| ""| |
|image-url| Image URL.| None| '$(tasks.build-image-index.results.IMAGE_URL)'|
### clamav-scan task parameters
|name|description|default value|already set by|
|---|---|---|---|
|ca-trust-config-map-key| The name of the key in the ConfigMap that contains the CA bundle data.| ca-bundle.crt| |
|ca-trust-config-map-name| The name of the ConfigMap to read CA bundle data from.| trusted-ca| |
|clamd-max-threads| Maximum number of threads clamd runs.| 8| |
|docker-auth| unused| ""| |
|image-arch| Image arch.| ""| |
|image-digest| Image digest to scan.| None| '$(tasks.build-image-index.results.IMAGE_DIGEST)'|
|image-url| Image URL.| None| '$(tasks.build-image-index.results.IMAGE_URL)'|
### deprecated-image-check task parameters
|name|description|default value|already set by|
|---|---|---|---|
|BASE_IMAGES_DIGESTS| Digests of base build images.| ""| |
|CA_TRUST_CONFIG_MAP_KEY| The name of the key in the ConfigMap that contains the CA bundle data.| ca-bundle.crt| |
|CA_TRUST_CONFIG_MAP_NAME| The name of the ConfigMap to read CA bundle data from.| trusted-ca| |
|IMAGE_DIGEST| Image digest.| None| '$(tasks.build-image-index.results.IMAGE_DIGEST)'|
|IMAGE_URL| Fully qualified image name.| None| '$(tasks.build-image-index.results.IMAGE_URL)'|
|POLICY_DIR| Path to directory containing Conftest policies.| /project/repository/| |
|POLICY_NAMESPACE| Namespace for Conftest policy.| required_checks| |
### ecosystem-cert-preflight-checks task parameters
|name|description|default value|already set by|
|---|---|---|---|
|artifact-type| The type of artifact. Select from application, operatorbundle, or introspect.| introspect| |
|ca-trust-config-map-key| The name of the key in the ConfigMap that contains the CA bundle data.| ca-bundle.crt| |
|ca-trust-config-map-name| The name of the ConfigMap to read CA bundle data from.| trusted-ca| |
|image-url| Image url to scan.| None| '$(tasks.build-image-index.results.IMAGE_URL)'|
|platform| The platform the image is built on.| ""| |
### git-clone task parameters
|name|description|default value|already set by|
|---|---|---|---|
|caTrustConfigMapKey| The name of the key in the ConfigMap that contains the CA bundle data.| ca-bundle.crt| |
|caTrustConfigMapName| The name of the ConfigMap to read CA bundle data from.| trusted-ca| |
|deleteExisting| Clean out the contents of the destination directory if it already exists before cloning.| true| |
|depth| Perform a shallow clone, fetching only the most recent N commits.| 1| |
|enableSymlinkCheck| Check symlinks in the repo. If they're pointing outside of the repo, the build will fail. | true| |
|fetchTags| Fetch all tags for the repo.| false| |
|httpProxy| HTTP proxy server for non-SSL requests.| ""| |
|httpsProxy| HTTPS proxy server for SSL requests.| ""| |
|logLevel| Log level for the git-clone command.| info| |
|mergeSourceDepth| Perform a shallow fetch of the target branch, fetching only the most recent N commits. If empty, fetches the full history of the target branch. | ""| |
|mergeSourceRepoUrl| URL of the repository to fetch the target branch from when mergeTargetBranch is true. If empty, uses the same repository (origin). This allows merging a branch from a different repository. | ""| |
|mergeTargetBranch| Set to "true" to merge the targetBranch into the checked-out revision.| false| |
|noProxy| Opt out of proxying HTTP/HTTPS requests.| ""| |
|refspec| Refspec to fetch before checking out revision.| ""| |
|revision| Revision to checkout. (branch, tag, sha, ref, etc...)| ""| '$(params.revision)'|
|shortCommitLength| Minimum length of the short commit SHA. Git may return a longer prefix if needed for uniqueness.| 7| |
|sparseCheckoutDirectories| Define the directory patterns to match or exclude when performing a sparse checkout.| ""| |
|sslVerify| Set the `http.sslVerify` global git config. Setting this to `false` is not advised unless you are sure that you trust your git remote.| true| |
|subdirectory| Subdirectory inside the `output` Workspace to clone the repo into.| source| |
|submodulePaths| Comma-separated list of specific submodule paths to initialize and fetch. Only submodules in the specified directories and their subdirectories will be fetched. Empty string fetches all submodules. Parameter "submodules" must be set to "true" to make this parameter applicable.| ""| |
|submodules| Initialize and fetch git submodules.| true| |
|symlinkCheckIgnorePattern| CSV list of path patterns to exclude from the symlink check. Symlinks whose paths match are not checked. Patterns are relative to the checkout directory and must not start with '/'. Use '*' and '?' as wildcards ('*' matches across '/'). Quote patterns containing commas using CSV double quotes. | ""| |
|targetBranch| The target branch to merge into the revision (if mergeTargetBranch is true).| main| |
|url| Repository URL to clone from.| None| '$(params.git-url)'|
### init task parameters
|name|description|default value|already set by|
|---|---|---|---|
|enable-cache-proxy| Enable cache proxy configuration| false| '$(params.enable-cache-proxy)'|
### package-operator-package task parameters
|name|description|default value|already set by|
|---|---|---|---|
|DST_URL| URL where to push the generated pko package to.| None| '$(params.output-image)'|
|LABELS| Additional key=value labels to add to the OCI image.| []| '['$(params.labels[*])']'|
|SRC_PATH| Path of the directory within the repository that contains package manifest.| None| '$(params.path-context)'|
### prefetch-dependencies task parameters
|name|description|default value|already set by|
|---|---|---|---|
|ACTIVATION_KEY| Name of secret which contains subscription activation key| activation-key| |
|SERVICE_CA_TRUST_CONFIG_MAP_KEY| The name of the key in the ConfigMap that contains the service CA bundle data. Used to verify TLS connections to in-cluster services such as the package registry proxy.| service-ca.crt| |
|SERVICE_CA_TRUST_CONFIG_MAP_NAME| The name of the ConfigMap to read service CA bundle data from. Used to verify TLS connections to in-cluster services such as the package registry proxy.| openshift-service-ca.crt| |
|caTrustConfigMapKey| The name of the key in the ConfigMap that contains the CA bundle data.| ca-bundle.crt| |
|caTrustConfigMapName| The name of the ConfigMap to read CA bundle data from.| trusted-ca| |
|config-file-content| Pass configuration to the prefetch tool. Note this needs to be passed as a YAML-formatted config dump, not as a file path! | ""| |
|enable-package-registry-proxy| Use the package registry proxy when prefetching dependencies| true| '$(params.enable-package-registry-proxy)'|
|input| Configures project packages that will have their dependencies prefetched.| None| '$(params.prefetch-input)'|
|log-level| Set the logging level (debug, info, warn, error, fatal).| debug| |
|mode| Control how input requirement violations are handled: strict (errors) or permissive (warnings).| strict| |
|pip-index-url| Python package index URL to use when prefetching pip dependencies. Used as a fallback when requirements.txt does not specify --index-url. When empty (default), the standard PyPI index is used.| ""| |
|sbom-type| Select the SBOM format to generate. Valid values: spdx, cyclonedx.| spdx| |
### rpms-signature-scan task parameters
|name|description|default value|already set by|
|---|---|---|---|
|ca-trust-config-map-key| The name of the key in the ConfigMap that contains the CA bundle data.| ca-bundle.crt| |
|ca-trust-config-map-name| The name of the ConfigMap to read CA bundle data from.| trusted-ca| |
|image-digest| Image digest to scan| None| '$(tasks.build-image-index.results.IMAGE_DIGEST)'|
|image-url| Image URL| None| '$(tasks.build-image-index.results.IMAGE_URL)'|
|workdir| Directory that will be used for storing temporary files produced by this task. | /tmp| |
### sast-shell-check task parameters
|name|description|default value|already set by|
|---|---|---|---|
|IMP_FINDINGS_ONLY| Whether to include important findings only| true| |
|KFP_GIT_URL| Known False Positives (KFP) git URL (optionally taking a revision delimited by \#). Defaults to "SITE_DEFAULT", which means the default value "https://gitlab.cee.redhat.com/osh/known-false-positives.git" for internal Konflux instance and empty string for external Konflux instance. If set to an empty string, the KFP filtering is disabled.| SITE_DEFAULT| |
|PROJECT_NAME| Name of the scanned project, used to find path exclusions. By default, the Konflux component name will be used.| ""| |
|RECORD_EXCLUDED| Whether to record the excluded findings (default to false). If `true`, the excluded findings will be stored in `excluded-findings.json`. | false| |
|TARGET_DIRS| Target directories in component's source code. Multiple values should be separated with commas.| .| '$(params.sast-target-dirs)'|
|caTrustConfigMapKey| The name of the key in the ConfigMap that contains the CA bundle data.| ca-bundle.crt| |
|caTrustConfigMapName| The name of the ConfigMap to read CA bundle data from.| trusted-ca| |
|image-digest| Image digest to report findings for.| ""| '$(tasks.build-image-index.results.IMAGE_DIGEST)'|
|image-url| Image URL.| ""| '$(tasks.build-image-index.results.IMAGE_URL)'|
### sast-snyk-check task parameters
|name|description|default value|already set by|
|---|---|---|---|
|ARGS| Append arguments.| ""| |
|IGNORE_FILE_PATHS| Directories or files to be excluded from Snyk scan (Comma-separated). Useful to split the directories of a git repo across multiple components.| ""| |
|IMP_FINDINGS_ONLY| Report only important findings in task result. Default is "true". To report all findings in task result, specify "false". Uploaded SARIF report to remote registry always includes all findings, regardless of severity level.| true| |
|KFP_GIT_URL| Known False Positives (KFP) git URL (optionally taking a revision delimited by \#). Defaults to "SITE_DEFAULT", which means the default value "https://gitlab.cee.redhat.com/osh/known-false-positives.git" for internal Konflux instance and empty string for external Konflux instance. If set to an empty string, the KFP filtering is disabled.| SITE_DEFAULT| |
|PROJECT_NAME| Name of the scanned project, used to find path exclusions. By default, the Konflux component name will be used.| ""| |
|RECORD_EXCLUDED| Write excluded records in file. Useful for auditing (defaults to false).| false| |
|SNYK_SECRET| Name of secret which contains Snyk token.| snyk-secret| |
|TARGET_DIRS| Target directories in component's source code. Multiple values should be separated with commas.| .| '$(params.sast-target-dirs)'|
|caTrustConfigMapKey| The name of the key in the ConfigMap that contains the CA bundle data.| ca-bundle.crt| |
|caTrustConfigMapName| The name of the ConfigMap to read CA bundle data from.| trusted-ca| |
|image-digest| Digest of the image to scan.| None| '$(tasks.build-image-index.results.IMAGE_DIGEST)'|
|image-url| Image URL.| None| '$(tasks.build-image-index.results.IMAGE_URL)'|
### sast-unicode-check task parameters
|name|description|default value|already set by|
|---|---|---|---|
|FIND_UNICODE_CONTROL_ARGS| arguments for find-unicode-control command.| -p bidi -v -d -t| |
|KFP_GIT_URL| Known False Positives (KFP) git URL (optionally taking a revision delimited by \#). Defaults to "SITE_DEFAULT", which means the default value "https://gitlab.cee.redhat.com/osh/known-false-positives.git" for internal Konflux instance and empty string for external Konflux instance. If set to an empty string, the KFP filtering is disabled.| SITE_DEFAULT| |
|PROJECT_NAME| Name of the scanned project, used to find path exclusions. By default, the Konflux component name will be used.| ""| |
|RECORD_EXCLUDED| Whether to record the excluded findings (defaults to false). If `true`, the excluded findings will be stored in `excluded-findings.json`. | false| |
|TARGET_DIRS| Target directories in component's source code. Multiple values should be separated with commas.| .| '$(params.sast-target-dirs)'|
|caTrustConfigMapKey| The name of the key in the ConfigMap that contains the CA bundle data.| ca-bundle.crt| |
|caTrustConfigMapName| The name of the ConfigMap to read CA bundle data from.| trusted-ca| |
|image-digest| Image digest used for ORAS upload.| None| '$(tasks.build-image-index.results.IMAGE_DIGEST)'|
|image-url| Image URL used for ORAS upload.| None| '$(tasks.build-image-index.results.IMAGE_URL)'|
### source-build task parameters
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
### build-image-index task results
|name|description|used in params (taskname:taskparam)
|---|---|---|
|IMAGES| List of all referenced image manifests| |
|IMAGE_DIGEST| Digest of the image just built| build-source-image:BINARY_IMAGE_DIGEST ; deprecated-base-image-check:IMAGE_DIGEST ; clair-scan:image-digest ; sast-snyk-check:image-digest ; clamav-scan:image-digest ; sast-shell-check:image-digest ; sast-unicode-check:image-digest ; apply-tags:IMAGE_DIGEST ; rpms-signature-scan:image-digest|
|IMAGE_REF| Image reference of the built image containing both the repository and the digest| |
|IMAGE_URL| Image repository and tag where the built image was pushed| build-source-image:BINARY_IMAGE ; deprecated-base-image-check:IMAGE_URL ; clair-scan:image-url ; ecosystem-cert-preflight-checks:image-url ; sast-snyk-check:image-url ; clamav-scan:image-url ; sast-shell-check:image-url ; sast-unicode-check:image-url ; apply-tags:IMAGE_URL ; rpms-signature-scan:image-url|
|SBOM_BLOB_URL| Reference of SBOM blob digest to enable digest-based verification from provenance| |
### clair-scan task results
|name|description|used in params (taskname:taskparam)
|---|---|---|
|IMAGES_PROCESSED| Images processed in the task.| |
|REPORTS| Mapping of image digests to report digests| |
|SCAN_OUTPUT| Clair scan result.| |
|TEST_OUTPUT| Tekton task test output.| |
### clamav-scan task results
|name|description|used in params (taskname:taskparam)
|---|---|---|
|IMAGES_PROCESSED| Images processed in the task.| |
|TEST_OUTPUT| Tekton task test output.| |
### deprecated-image-check task results
|name|description|used in params (taskname:taskparam)
|---|---|---|
|IMAGES_PROCESSED| Images processed in the task.| |
|TEST_OUTPUT| Tekton task test output.| |
### ecosystem-cert-preflight-checks task results
|name|description|used in params (taskname:taskparam)
|---|---|---|
|ARTIFACT_TYPE| The artifact type, either introspected or set.| |
|ARTIFACT_TYPE_SET_BY| How the artifact type was set.| |
|IMAGES_PROCESSED| Collected image digests| |
|TEST_OUTPUT| Ecosystem checks pass or fail outcome.| |
### git-clone task results
|name|description|used in params (taskname:taskparam)
|---|---|---|
|CHAINS-GIT_COMMIT| The precise commit SHA that was fetched by this Task. This result uses Chains type hinting to include in the provenance.| |
|CHAINS-GIT_URL| The precise URL that was fetched by this Task. This result uses Chains type hinting to include in the provenance.| |
|commit| The precise commit SHA that was fetched by this Task.| |
|commit-timestamp| The commit timestamp of the checkout| |
|merged_sha| The SHA of the commit after merging the target branch (if the param mergeTargetBranch is true).| |
|short-commit| Abbreviated commit SHA for the checkout. At least params.shortCommitLength characters; longer if Git requires more for uniqueness.| |
|url| The precise URL that was fetched by this Task.| |
### init task results
|name|description|used in params (taskname:taskparam)
|---|---|---|
|http-proxy| HTTP proxy URL for cache proxy (when enable-cache-proxy is true)| |
|no-proxy| NO_PROXY value for cache proxy (when enable-cache-proxy is true)| |
### package-operator-package task results
|name|description|used in params (taskname:taskparam)
|---|---|---|
|IMAGE_DIGEST| Digest of the package just built| |
|IMAGE_REF| Image reference of the built package| |
|IMAGE_URL| Image repository and tag where the built package was pushed| build-image-index:IMAGES|
|SBOM_BLOB_URL| Reference of SBOM blob digest to enable digest-based verification from provenance| |
### rpms-signature-scan task results
|name|description|used in params (taskname:taskparam)
|---|---|---|
|IMAGES_PROCESSED| Images processed in the task.| |
|RPMS_DATA| Information about signed and unsigned RPMs| |
|TEST_OUTPUT| Tekton task test output.| |
### sast-shell-check task results
|name|description|used in params (taskname:taskparam)
|---|---|---|
|TEST_OUTPUT| Tekton task test output.| |
### sast-snyk-check task results
|name|description|used in params (taskname:taskparam)
|---|---|---|
|TEST_OUTPUT| Tekton task test output.| |
### sast-unicode-check task results
|name|description|used in params (taskname:taskparam)
|---|---|---|
|TEST_OUTPUT| Tekton task test output.| |
### source-build task results
|name|description|used in params (taskname:taskparam)
|---|---|---|
|BUILD_RESULT| Build result.| |
|IMAGE_REF| Image reference of the built image.| |
|SOURCE_IMAGE_DIGEST| The source image digest.| |
|SOURCE_IMAGE_URL| The source image url.| |

## Workspaces
|name|description|optional|used in tasks
|---|---|---|---|
|git-auth| |True| clone-repository:basic-auth ; prefetch-dependencies:git-basic-auth|
|netrc| |True| prefetch-dependencies:netrc|
|workspace| |False| clone-repository:output ; prefetch-dependencies:source ; build-container:package ; build-source-image:workspace ; sast-snyk-check:workspace ; sast-shell-check:workspace ; sast-unicode-check:workspace|
## Available workspaces from tasks
### git-clone task workspaces
|name|description|optional|workspace from pipeline
|---|---|---|---|
|basic-auth| A Workspace containing a .gitconfig and .git-credentials file or username and password. These will be copied to the user's home before any git commands are run. Any other files in this Workspace are ignored. It is strongly recommended to use ssh-directory over basic-auth whenever possible and to bind a Secret to this Workspace over other volume types. | True| git-auth|
|output| The git repo will be cloned onto the volume backing this Workspace.| False| workspace|
|ssh-directory| A .ssh directory with private key, known_hosts, config, etc. Copied to the user's home before git commands are executed. Used to authenticate with the git remote when performing the clone. Binding a Secret to this Workspace is strongly recommended over other volume types. | True| |
### package-operator-package task workspaces
|name|description|optional|workspace from pipeline
|---|---|---|---|
|source| Workspace containing the source code to build.| False| workspace|
### prefetch-dependencies task workspaces
|name|description|optional|workspace from pipeline
|---|---|---|---|
|git-basic-auth| A Workspace containing a .gitconfig and .git-credentials file or username and password. These will be copied to the user's home before prefetch is run. Any other files in this Workspace are ignored. It is strongly recommended to bind a Secret to this Workspace over other volume types. | True| git-auth|
|netrc| Workspace containing a .netrc file. Prefetch will use the credentials in this file when performing http(s) requests. | True| netrc|
|source| Workspace with the source code, prefetch artifacts will be stored on the workspace as well| False| workspace|
### sast-shell-check task workspaces
|name|description|optional|workspace from pipeline
|---|---|---|---|
|workspace| | False| workspace|
### sast-snyk-check task workspaces
|name|description|optional|workspace from pipeline
|---|---|---|---|
|workspace| | False| workspace|
### sast-unicode-check task workspaces
|name|description|optional|workspace from pipeline
|---|---|---|---|
|workspace| | False| workspace|
### source-build task workspaces
|name|description|optional|workspace from pipeline
|---|---|---|---|
|workspace| The workspace where source code is included.| False| workspace|
