# "maven-zip-build-oci-ta pipeline"
This pipeline will build the maven zip to oci-artifact while maintaining trust after pipeline customization.

_Uses `prefetch-dependencies` to fetch all artifacts which will be the content of the maven zip, and then uses `build-maven-zip-oci-ta` to create zip and push it to quay.io as oci-artifact. Information is shared between tasks using OCI artifacts instead of PVCs.
This pipeline is pushed as a Tekton bundle to [quay.io](https://quay.io/repository/konflux-ci/tekton-catalog/pipeline-maven-zip-build-oci-ta?tab=tags)_

## Parameters
|name|description|default value|used in (taskname:taskrefversion:taskparam)|
|---|---|---|---|
|enable-cache-proxy| Enable cache proxy configuration| false| init:0.4:enable-cache-proxy|
|enable-package-registry-proxy| Use the package registry proxy when prefetching dependencies| true| prefetch-dependencies:0.3:enable-package-registry-proxy|
|git-url| Source Repository URL| None| clone-repository:0.1:url|
|image-expires-after| Image tag expiration time, time values could be something like 1h, 2d, 3w for hours, days, and weeks, respectively.| | clone-repository:0.1:ociArtifactExpiresAfter ; prefetch-dependencies:0.3:ociArtifactExpiresAfter ; build-oci-artifact:0.1:IMAGE_EXPIRES_AFTER|
|output-image| Fully Qualified Output Image| None| clone-repository:0.1:ociStorage ; prefetch-dependencies:0.3:ociStorage ; build-oci-artifact:0.1:IMAGE|
|prefetch-input| Build dependencies to be prefetched| generic| prefetch-dependencies:0.3:input|
|revision| Revision of the Source Repository| | clone-repository:0.1:revision|
|skip-checks| Skip checks against built image| false| |

## Available params from tasks
### build-maven-zip-oci-ta:0.1 task parameters
|name|description|default value|already set by|
|---|---|---|---|
|CACHI2_ARTIFACT| The Trusted Artifact URI pointing to the artifact with the prefetched dependencies.| ""| '$(tasks.prefetch-dependencies.results.CACHI2_ARTIFACT)'|
|FILE_NAME| The zip bundle file name of archived artifacts| maven-repository| |
|IMAGE| Reference of the OCI-Artifact this build task will produce.| None| '$(params.output-image)'|
|IMAGE_EXPIRES_AFTER| Delete image tag after specified time. Empty means to keep the image tag. Time values could be something like 1h, 2d, 3w for hours, days, and weeks, respectively.| ""| '$(params.image-expires-after)'|
|PREFETCH_ROOT| The root directory of the artifacts under the prefetched directory. Will be kept in the maven zip as the top directory for all artifacts.| maven-repository| |
|SBOM_SKIP_VALIDATION| Flag to enable or disable SBOM validation before save. Validation is optional - use this if you are experiencing performance issues.| false| |
|caTrustConfigMapKey| The name of the key in the ConfigMap that contains the CA bundle data.| ca-bundle.crt| |
|caTrustConfigMapName| The name of the ConfigMap to read CA bundle data from.| trusted-ca| |
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
### prefetch-dependencies-oci-ta:0.3 task parameters
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
### sast-shell-check-oci-ta:0.1 task parameters
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
|image-digest| Image digest to report findings for.| ""| '$(tasks.build-oci-artifact.results.IMAGE_DIGEST)'|
|image-url| Image URL.| ""| '$(tasks.build-oci-artifact.results.IMAGE_URL)'|
### sast-snyk-check-oci-ta:0.4 task parameters
|name|description|default value|already set by|
|---|---|---|---|
|ARGS| Append arguments.| ""| |
|CACHI2_ARTIFACT| The Trusted Artifact URI pointing to the artifact with the prefetched dependencies.| ""| '$(tasks.prefetch-dependencies.results.CACHI2_ARTIFACT)'|
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
|image-digest| Digest of the image to scan.| None| '$(tasks.build-oci-artifact.results.IMAGE_DIGEST)'|
|image-url| Image URL.| None| '$(tasks.build-oci-artifact.results.IMAGE_URL)'|
### sast-unicode-check-oci-ta:0.4 task parameters
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
|image-digest| Image digest used for ORAS upload.| None| '$(tasks.build-oci-artifact.results.IMAGE_DIGEST)'|
|image-url| Image URL used for ORAS upload.| None| '$(tasks.build-oci-artifact.results.IMAGE_URL)'|

## Results
|name|description|value|
|---|---|---|
|CHAINS-GIT_COMMIT| |$(tasks.clone-repository.results.commit)|
|CHAINS-GIT_URL| |$(tasks.clone-repository.results.url)|
|IMAGE_DIGEST| |$(tasks.build-oci-artifact.results.IMAGE_DIGEST)|
|IMAGE_URL| |$(tasks.build-oci-artifact.results.IMAGE_URL)|
## Available results from tasks
### build-maven-zip-oci-ta:0.1 task results
|name|description|used in params (taskname:taskrefversion:taskparam)
|---|---|---|
|IMAGE_DIGEST| Digest of the OCI-Artifact just built| sast-snyk-check:0.4:image-digest ; sast-shell-check:0.1:image-digest ; sast-unicode-check:0.4:image-digest|
|IMAGE_REF| OCI-Artifact reference of the built OCI-Artifact| |
|IMAGE_URL| OCI-Artifact repository and tag where the built OCI-Artifact was pushed| sast-snyk-check:0.4:image-url ; sast-shell-check:0.1:image-url ; sast-unicode-check:0.4:image-url|
|SBOM_BLOB_URL| Reference of SBOM blob digest to enable digest-based verification from provenance| |
### git-clone-oci-ta:0.1 task results
|name|description|used in params (taskname:taskrefversion:taskparam)
|---|---|---|
|CHAINS-GIT_COMMIT| The precise commit SHA that was fetched by this Task. This result uses Chains type hinting to include in the provenance.| |
|CHAINS-GIT_URL| The precise URL that was fetched by this Task. This result uses Chains type hinting to include in the provenance.| |
|SOURCE_ARTIFACT| The Trusted Artifact URI pointing to the artifact with the application source code.| prefetch-dependencies:0.3:SOURCE_ARTIFACT|
|commit| The precise commit SHA that was fetched by this Task.| |
|commit-timestamp| The commit timestamp of the checkout| |
|merged_sha| The SHA of the commit after merging the target branch (if the param mergeTargetBranch is true).| |
|short-commit| The commit SHA that was fetched by this Task limited to params.shortCommitLength number of characters| |
|url| The precise URL that was fetched by this Task.| |
### init:0.4 task results
|name|description|used in params (taskname:taskrefversion:taskparam)
|---|---|---|
|http-proxy| HTTP proxy URL for cache proxy (when enable-cache-proxy is true)| |
|no-proxy| NO_PROXY value for cache proxy (when enable-cache-proxy is true)| |
### prefetch-dependencies-oci-ta:0.3 task results
|name|description|used in params (taskname:taskrefversion:taskparam)
|---|---|---|
|CACHI2_ARTIFACT| The Trusted Artifact URI pointing to the artifact with the prefetched dependencies.| build-oci-artifact:0.1:CACHI2_ARTIFACT ; sast-snyk-check:0.4:CACHI2_ARTIFACT ; sast-shell-check:0.1:CACHI2_ARTIFACT ; sast-unicode-check:0.4:CACHI2_ARTIFACT|
|SOURCE_ARTIFACT| The Trusted Artifact URI pointing to the artifact with the application source code.| sast-snyk-check:0.4:SOURCE_ARTIFACT ; sast-shell-check:0.1:SOURCE_ARTIFACT ; sast-unicode-check:0.4:SOURCE_ARTIFACT|
### sast-shell-check-oci-ta:0.1 task results
|name|description|used in params (taskname:taskrefversion:taskparam)
|---|---|---|
|TEST_OUTPUT| Tekton task test output.| |
### sast-snyk-check-oci-ta:0.4 task results
|name|description|used in params (taskname:taskrefversion:taskparam)
|---|---|---|
|TEST_OUTPUT| Tekton task test output.| |
### sast-unicode-check-oci-ta:0.4 task results
|name|description|used in params (taskname:taskrefversion:taskparam)
|---|---|---|
|TEST_OUTPUT| Tekton task test output.| |

## Workspaces
|name|description|optional|used in tasks
|---|---|---|---|
|git-auth| |True| clone-repository:0.1:basic-auth ; prefetch-dependencies:0.3:git-basic-auth|
|netrc| |True| prefetch-dependencies:0.3:netrc|
|workspace| |False| |
## Available workspaces from tasks
### git-clone-oci-ta:0.1 task workspaces
|name|description|optional|workspace from pipeline
|---|---|---|---|
|basic-auth| A Workspace containing a .gitconfig and .git-credentials file or username and password. These will be copied to the user's home before any git commands are run. Any other files in this Workspace are ignored. It is strongly recommended to use ssh-directory over basic-auth whenever possible and to bind a Secret to this Workspace over other volume types. | True| git-auth|
|ssh-directory| A .ssh directory with private key, known_hosts, config, etc. Copied to the user's home before git commands are executed. Used to authenticate with the git remote when performing the clone. Binding a Secret to this Workspace is strongly recommended over other volume types. | True| |
### prefetch-dependencies-oci-ta:0.3 task workspaces
|name|description|optional|workspace from pipeline
|---|---|---|---|
|git-basic-auth| A Workspace containing a .gitconfig and .git-credentials file or username and password. These will be copied to the user's home before prefetch is run. Any other files in this Workspace are ignored. It is strongly recommended to bind a Secret to this Workspace over other volume types. | True| git-auth|
|netrc| Workspace containing a .netrc file. Prefetch will use the credentials in this file when performing http(s) requests. | True| netrc|
