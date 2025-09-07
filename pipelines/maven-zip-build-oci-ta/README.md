# "maven-zip-build-oci-ta pipeline"
This pipeline will build the maven zip to oci-artifact while maintaining trust after pipeline customization.

_Uses `prefetch-dependencies` to fetch all artifacts which will be the content of the maven zip, and then uses `build-maven-zip-oci-ta` to create zip and push it to quay.io as oci-artifact. Information is shared between tasks using OCI artifacts instead of PVCs.
This pipeline is pushed as a Tekton bundle to [quay.io](https://quay.io/repository/konflux-ci/tekton-catalog/pipeline-maven-zip-build-oci-ta?tab=tags)_

## Parameters
|name|description|default value|used in (taskname:taskrefversion:taskparam)|
|---|---|---|---|
|git-url| Source Repository URL| None| clone-repository:0.1:url|
|image-expires-after| Image tag expiration time, time values could be something like 1h, 2d, 3w for hours, days, and weeks, respectively.| | clone-repository:0.1:ociArtifactExpiresAfter ; prefetch-dependencies:0.2:ociArtifactExpiresAfter ; build-oci-artifact:0.1:IMAGE_EXPIRES_AFTER|
|output-image| Fully Qualified Output Image| None| init:0.2:image-url ; clone-repository:0.1:ociStorage ; prefetch-dependencies:0.2:ociStorage ; build-oci-artifact:0.1:IMAGE ; sast-coverity-check:0.3:IMAGE|
|prefetch-input| Build dependencies to be prefetched| generic| prefetch-dependencies:0.2:input|
|rebuild| Force rebuild image| false| init:0.2:rebuild|
|revision| Revision of the Source Repository| | clone-repository:0.1:revision|
|skip-checks| Skip checks against built image| false| init:0.2:skip-checks|

## Available params from tasks
### build-maven-zip-oci-ta:0.1 task parameters
|name|description|default value|already set by|
|---|---|---|---|
|CACHI2_ARTIFACT| The Trusted Artifact URI pointing to the artifact with the prefetched dependencies.| | '$(tasks.prefetch-dependencies.results.CACHI2_ARTIFACT)'|
|FILE_NAME| The zip bundle file name of archived artifacts| maven-repository| |
|IMAGE| Reference of the OCI-Artifact this build task will produce.| None| '$(params.output-image)'|
|IMAGE_EXPIRES_AFTER| Delete image tag after specified time. Empty means to keep the image tag. Time values could be something like 1h, 2d, 3w for hours, days, and weeks, respectively.| | '$(params.image-expires-after)'|
|PREFETCH_ROOT| The root directory of the artifacts under the prefetched directory. Will be kept in the maven zip as the top directory for all artifacts.| maven-repository| |
|caTrustConfigMapKey| The name of the key in the ConfigMap that contains the CA bundle data.| ca-bundle.crt| |
|caTrustConfigMapName| The name of the ConfigMap to read CA bundle data from.| trusted-ca| |
### coverity-availability-check:0.2 task parameters
|name|description|default value|already set by|
|---|---|---|---|
|AUTH_TOKEN_COVERITY_IMAGE| Name of secret which contains the authentication token for pulling the Coverity image.| auth-token-coverity-image| |
|COV_LICENSE| Name of secret which contains the Coverity license| cov-license| |
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
|mergeTargetBranch| Set to "true" to merge the targetBranch into the checked-out revision.| false| |
|noProxy| Opt out of proxying HTTP/HTTPS requests.| | |
|ociArtifactExpiresAfter| Expiration date for the trusted artifacts created in the OCI repository. An empty string means the artifacts do not expire.| | '$(params.image-expires-after)'|
|ociStorage| The OCI repository where the Trusted Artifacts are stored.| None| '$(params.output-image).git'|
|refspec| Refspec to fetch before checking out revision.| | |
|revision| Revision to checkout. (branch, tag, sha, ref, etc...)| | '$(params.revision)'|
|shortCommitLength| Length of short commit SHA| 7| |
|sparseCheckoutDirectories| Define the directory patterns to match or exclude when performing a sparse checkout.| | |
|sslVerify| Set the `http.sslVerify` global git config. Setting this to `false` is not advised unless you are sure that you trust your git remote.| true| |
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
### prefetch-dependencies-oci-ta:0.2 task parameters
|name|description|default value|already set by|
|---|---|---|---|
|ACTIVATION_KEY| Name of secret which contains subscription activation key| activation-key| |
|SOURCE_ARTIFACT| The Trusted Artifact URI pointing to the artifact with the application source code.| None| '$(tasks.clone-repository.results.SOURCE_ARTIFACT)'|
|caTrustConfigMapKey| The name of the key in the ConfigMap that contains the CA bundle data.| ca-bundle.crt| |
|caTrustConfigMapName| The name of the ConfigMap to read CA bundle data from.| trusted-ca| |
|config-file-content| Pass configuration to the prefetch tool. Note this needs to be passed as a YAML-formatted config dump, not as a file path! | | |
|dev-package-managers| Enable in-development package managers. WARNING: the behavior may change at any time without notice. Use at your own risk. | false| |
|input| Configures project packages that will have their dependencies prefetched.| None| '$(params.prefetch-input)'|
|log-level| Set prefetch tool log level (debug, info, warning, error)| info| |
|ociArtifactExpiresAfter| Expiration date for the trusted artifacts created in the OCI repository. An empty string means the artifacts do not expire.| | '$(params.image-expires-after)'|
|ociStorage| The OCI repository where the Trusted Artifacts are stored.| None| '$(params.output-image).prefetch'|
|sbom-type| Select the SBOM format to generate. Valid values: spdx, cyclonedx.| spdx| |
### sast-coverity-check-oci-ta:0.3 task parameters
|name|description|default value|already set by|
|---|---|---|---|
|ACTIVATION_KEY| Name of secret which contains subscription activation key| activation-key| |
|ADDITIONAL_BASE_IMAGES| Additional base image references to include to the SBOM. Array of image_reference_with_digest strings| []| |
|ADDITIONAL_SECRET| Name of a secret which will be made available to the build with 'buildah build --secret' at /run/secrets/$ADDITIONAL_SECRET| does-not-exist| |
|ADD_CAPABILITIES| Comma separated list of extra capabilities to add when running 'buildah build'| | |
|ANNOTATIONS| Additional key=value annotations that should be applied to the image| []| |
|ANNOTATIONS_FILE| Path to a file with additional key=value annotations that should be applied to the image| | |
|BUILDAH_FORMAT| The format for the resulting image's mediaType. Valid values are oci (default) or docker.| oci| |
|BUILD_ARGS| Array of --build-arg values ("arg=value" strings)| []| |
|BUILD_ARGS_FILE| Path to a file with build arguments, see https://www.mankier.com/1/buildah-build#--build-arg-file| | |
|CACHI2_ARTIFACT| The Trusted Artifact URI pointing to the artifact with the prefetched dependencies.| | '$(tasks.prefetch-dependencies.results.CACHI2_ARTIFACT)'|
|COMMIT_SHA| The image is built from this commit.| | |
|CONTEXT| Path to the directory to use as context.| .| |
|COV_ANALYZE_ARGS| Arguments to be appended to the cov-analyze command| --enable HARDCODED_CREDENTIALS --security --concurrency --spotbugs-max-mem=4096| |
|COV_LICENSE| Name of secret which contains the Coverity license| cov-license| |
|DOCKERFILE| Path to the Dockerfile to build.| ./Dockerfile| |
|ENTITLEMENT_SECRET| Name of secret which contains the entitlement certificates| etc-pki-entitlement| |
|HERMETIC| Determines if build will be executed without network access.| false| |
|HTTP_PROXY| HTTP/HTTPS proxy to use for the buildah pull and build operations. Will not be passed through to the container during the build process.| | |
|ICM_KEEP_COMPAT_LOCATION| Whether to keep compatibility location at /root/buildinfo/ for ICM injection| true| |
|IMAGE| The task will build a container image and tag it locally as $IMAGE, but will not push the image anywhere. Due to the relationship between this task and the buildah task, the parameter is required, but its value is mostly irrelevant.| None| '$(params.output-image)'|
|IMAGE_EXPIRES_AFTER| Delete image tag after specified time. Empty means to keep the image tag. Time values could be something like 1h, 2d, 3w for hours, days, and weeks, respectively.| | |
|IMP_FINDINGS_ONLY| Report only important findings. Default is true. To report all findings, specify "false"| true| |
|INHERIT_BASE_IMAGE_LABELS| Determines if the image inherits the base image labels.| true| |
|KFP_GIT_URL| Known False Positives (KFP) git URL (optionally taking a revision delimited by \#). Defaults to "SITE_DEFAULT", which means the default value "https://gitlab.cee.redhat.com/osh/known-false-positives.git" for internal Konflux instance and empty string for external Konflux instance. If set to an empty string, the KFP filtering is disabled.| SITE_DEFAULT| |
|LABELS| Additional key=value labels that should be applied to the image| []| |
|NO_PROXY| Comma separated list of hosts or domains which should bypass the HTTP/HTTPS proxy.| | |
|PREFETCH_INPUT| In case it is not empty, the prefetched content should be made available to the build.| | |
|PRIVILEGED_NESTED| Whether to enable privileged mode, should be used only with remote VMs| false| |
|PROJECT_NAME| | | |
|PROXY_CA_TRUST_CONFIG_MAP_KEY| The name of the key in the ConfigMap that contains the proxy CA bundle data.| ca-bundle.crt| |
|PROXY_CA_TRUST_CONFIG_MAP_NAME| The name of the ConfigMap to read proxy CA bundle data from.| proxy-ca-bundle| |
|RECORD_EXCLUDED| | false| |
|SBOM_TYPE| Select the SBOM format to generate. Valid values: spdx, cyclonedx. Note: the SBOM from the prefetch task - if there is one - must be in the same format.| spdx| |
|SKIP_SBOM_GENERATION| Skip SBOM-related operations. This will likely cause EC policies to fail if enabled| false| |
|SKIP_UNUSED_STAGES| Whether to skip stages in Containerfile that seem unused by subsequent stages| true| |
|SOURCE_ARTIFACT| The Trusted Artifact URI pointing to the artifact with the application source code.| None| '$(tasks.prefetch-dependencies.results.SOURCE_ARTIFACT)'|
|SQUASH| Squash all new and previous layers added as a part of this build, as per --squash| false| |
|STORAGE_DRIVER| Storage driver to configure for buildah| overlay| |
|TARGET_DIRS| Target directories in component's source code. Multiple values should be separated with commas. This only applies to buildless capture, which is only attempted if buildful capture fails to produce and results.| .| |
|TARGET_STAGE| Target stage in Dockerfile to build. If not specified, the Dockerfile is processed entirely to (and including) its last stage.| | |
|TLSVERIFY| Verify the TLS on the registry endpoint (for push/pull to a non-TLS registry)| true| |
|WORKINGDIR_MOUNT| Mount the current working directory into the build using --volume $PWD:/$WORKINGDIR_MOUNT. Note that the $PWD will be the context directory for the build (see the CONTEXT param).| | |
|YUM_REPOS_D_FETCHED| Path in source workspace where dynamically-fetched repos are present| fetched.repos.d| |
|YUM_REPOS_D_SRC| Path in the git repository in which yum repository files are stored| repos.d| |
|YUM_REPOS_D_TARGET| Target path on the container in which yum repository files should be made available| /etc/yum.repos.d| |
|caTrustConfigMapKey| The name of the key in the ConfigMap that contains the CA bundle data.| ca-bundle.crt| |
|caTrustConfigMapName| The name of the ConfigMap to read CA bundle data from.| trusted-ca| |
|image-digest| Digest of the image to which the scan results should be associated.| None| '$(tasks.build-oci-artifact.results.IMAGE_DIGEST)'|
|image-url| URL of the image to which the scan results should be associated.| None| '$(tasks.build-oci-artifact.results.IMAGE_URL)'|
### sast-shell-check-oci-ta:0.1 task parameters
|name|description|default value|already set by|
|---|---|---|---|
|CACHI2_ARTIFACT| The Trusted Artifact URI pointing to the artifact with the prefetched dependencies.| | '$(tasks.prefetch-dependencies.results.CACHI2_ARTIFACT)'|
|IMP_FINDINGS_ONLY| Whether to include important findings only| true| |
|KFP_GIT_URL| Known False Positives (KFP) git URL (optionally taking a revision delimited by \#). Defaults to "SITE_DEFAULT", which means the default value "https://gitlab.cee.redhat.com/osh/known-false-positives.git" for internal Konflux instance and empty string for external Konflux instance. If set to an empty string, the KFP filtering is disabled.| SITE_DEFAULT| |
|PROJECT_NAME| Name of the scanned project, used to find path exclusions. By default, the Konflux component name will be used.| | |
|RECORD_EXCLUDED| Whether to record the excluded findings (default to false). If `true`, the excluded findings will be stored in `excluded-findings.json`. | false| |
|SOURCE_ARTIFACT| The Trusted Artifact URI pointing to the artifact with the application source code.| None| '$(tasks.prefetch-dependencies.results.SOURCE_ARTIFACT)'|
|TARGET_DIRS| Target directories in component's source code. Multiple values should be separated with commas.| .| |
|caTrustConfigMapKey| The name of the key in the ConfigMap that contains the CA bundle data.| ca-bundle.crt| |
|caTrustConfigMapName| The name of the ConfigMap to read CA bundle data from.| trusted-ca| |
|image-digest| Image digest to report findings for.| | '$(tasks.build-oci-artifact.results.IMAGE_DIGEST)'|
|image-url| Image URL.| | '$(tasks.build-oci-artifact.results.IMAGE_URL)'|
### sast-snyk-check-oci-ta:0.4 task parameters
|name|description|default value|already set by|
|---|---|---|---|
|ARGS| Append arguments.| | |
|CACHI2_ARTIFACT| The Trusted Artifact URI pointing to the artifact with the prefetched dependencies.| | '$(tasks.prefetch-dependencies.results.CACHI2_ARTIFACT)'|
|IGNORE_FILE_PATHS| Directories or files to be excluded from Snyk scan (Comma-separated). Useful to split the directories of a git repo across multiple components.| | |
|IMP_FINDINGS_ONLY| Report only important findings. Default is true. To report all findings, specify "false"| true| |
|KFP_GIT_URL| Known False Positives (KFP) git URL (optionally taking a revision delimited by \#). Defaults to "SITE_DEFAULT", which means the default value "https://gitlab.cee.redhat.com/osh/known-false-positives.git" for internal Konflux instance and empty string for external Konflux instance. If set to an empty string, the KFP filtering is disabled.| SITE_DEFAULT| |
|PROJECT_NAME| Name of the scanned project, used to find path exclusions. By default, the Konflux component name will be used.| | |
|RECORD_EXCLUDED| Write excluded records in file. Useful for auditing (defaults to false).| false| |
|SNYK_SECRET| Name of secret which contains Snyk token.| snyk-secret| |
|SOURCE_ARTIFACT| The Trusted Artifact URI pointing to the artifact with the application source code.| None| '$(tasks.prefetch-dependencies.results.SOURCE_ARTIFACT)'|
|TARGET_DIRS| Target directories in component's source code. Multiple values should be separated with commas.| .| |
|caTrustConfigMapKey| The name of the key in the ConfigMap that contains the CA bundle data.| ca-bundle.crt| |
|caTrustConfigMapName| The name of the ConfigMap to read CA bundle data from.| trusted-ca| |
|image-digest| Digest of the image to scan.| None| '$(tasks.build-oci-artifact.results.IMAGE_DIGEST)'|
|image-url| Image URL.| None| '$(tasks.build-oci-artifact.results.IMAGE_URL)'|
### sast-unicode-check-oci-ta:0.3 task parameters
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
|IMAGE_DIGEST| Digest of the OCI-Artifact just built| sast-snyk-check:0.4:image-digest ; sast-coverity-check:0.3:image-digest ; sast-shell-check:0.1:image-digest ; sast-unicode-check:0.3:image-digest|
|IMAGE_REF| OCI-Artifact reference of the built OCI-Artifact| |
|IMAGE_URL| OCI-Artifact repository and tag where the built OCI-Artifact was pushed| sast-snyk-check:0.4:image-url ; sast-coverity-check:0.3:image-url ; sast-shell-check:0.1:image-url ; sast-unicode-check:0.3:image-url|
|SBOM_BLOB_URL| Reference of SBOM blob digest to enable digest-based verification from provenance| |
### coverity-availability-check:0.2 task results
|name|description|used in params (taskname:taskrefversion:taskparam)
|---|---|---|
|STATUS| Tekton task simple status to be later checked| |
|TEST_OUTPUT| Tekton task result output.| |
### git-clone-oci-ta:0.1 task results
|name|description|used in params (taskname:taskrefversion:taskparam)
|---|---|---|
|CHAINS-GIT_COMMIT| The precise commit SHA that was fetched by this Task. This result uses Chains type hinting to include in the provenance.| |
|CHAINS-GIT_URL| The precise URL that was fetched by this Task. This result uses Chains type hinting to include in the provenance.| |
|SOURCE_ARTIFACT| The Trusted Artifact URI pointing to the artifact with the application source code.| prefetch-dependencies:0.2:SOURCE_ARTIFACT|
|commit| The precise commit SHA that was fetched by this Task.| |
|commit-timestamp| The commit timestamp of the checkout| |
|merged_sha| The SHA of the commit after merging the target branch (if the param mergeTargetBranch is true).| |
|short-commit| The commit SHA that was fetched by this Task limited to params.shortCommitLength number of characters| |
|url| The precise URL that was fetched by this Task.| |
### init:0.2 task results
|name|description|used in params (taskname:taskrefversion:taskparam)
|---|---|---|
|build| Defines if the image in param image-url should be built| |
### prefetch-dependencies-oci-ta:0.2 task results
|name|description|used in params (taskname:taskrefversion:taskparam)
|---|---|---|
|CACHI2_ARTIFACT| The Trusted Artifact URI pointing to the artifact with the prefetched dependencies.| build-oci-artifact:0.1:CACHI2_ARTIFACT ; sast-snyk-check:0.4:CACHI2_ARTIFACT ; sast-coverity-check:0.3:CACHI2_ARTIFACT ; sast-shell-check:0.1:CACHI2_ARTIFACT ; sast-unicode-check:0.3:CACHI2_ARTIFACT|
|SOURCE_ARTIFACT| The Trusted Artifact URI pointing to the artifact with the application source code.| sast-snyk-check:0.4:SOURCE_ARTIFACT ; sast-coverity-check:0.3:SOURCE_ARTIFACT ; sast-shell-check:0.1:SOURCE_ARTIFACT ; sast-unicode-check:0.3:SOURCE_ARTIFACT|
### sast-coverity-check-oci-ta:0.3 task results
|name|description|used in params (taskname:taskrefversion:taskparam)
|---|---|---|
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

## Workspaces
|name|description|optional|used in tasks
|---|---|---|---|
|git-auth| |True| clone-repository:0.1:basic-auth ; prefetch-dependencies:0.2:git-basic-auth|
|netrc| |True| prefetch-dependencies:0.2:netrc|
|workspace| |False| |
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
