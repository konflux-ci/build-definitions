# "maven-zip-build pipeline"
This pipeline will build the maven zip to oci-artifact.

_Uses `prefetch-dependencies` to fetch all artifacts which will be the content of the maven zip, and then uses `build-maven-zip` to create zip and push it to quay.io as oci-artifact.
This pipeline is pushed as a Tekton bundle to [quay.io](https://quay.io/repository/konflux-ci/tekton-catalog/pipeline-maven-zip-build?tab=tags)_

## Parameters
|name|description|default value|used in (taskname:taskrefversion:taskparam)|
|---|---|---|---|
|git-url| Source Repository URL| None| clone-repository:0.1:url|
|image-expires-after| Image tag expiration time, time values could be something like 1h, 2d, 3w for hours, days, and weeks, respectively.| | build-oci-artifact:0.1:IMAGE_EXPIRES_AFTER|
|output-image| Fully Qualified Output Image| None| show-summary:0.2:image-url ; init:0.2:image-url ; build-oci-artifact:0.1:IMAGE|
|prefetch-input| Build dependencies to be prefetched by Cachi2| generic| prefetch-dependencies:0.1:input|
|rebuild| Force rebuild image| false| init:0.2:rebuild|
|revision| Revision of the Source Repository| | clone-repository:0.1:revision|
|skip-checks| Skip checks against built image| false| init:0.2:skip-checks|

## Available params from tasks
### build-maven-zip:0.1 task parameters
|name|description|default value|already set by|
|---|---|---|---|
|FILE_NAME| The zip bundle file name of archived artifacts| maven-repository| |
|IMAGE| Reference of the OCI-Artifact this build task will produce.| None| '$(params.output-image)'|
|IMAGE_EXPIRES_AFTER| Delete image tag after specified time. Empty means to keep the image tag. Time values could be something like 1h, 2d, 3w for hours, days, and weeks, respectively.| | '$(params.image-expires-after)'|
|PREFETCH_ROOT| The root directory of the artifacts under the prefetched directory. Will be kept in the maven zip as the top directory for all artifacts.| maven-repository| |
|caTrustConfigMapKey| The name of the key in the ConfigMap that contains the CA bundle data.| ca-bundle.crt| |
|caTrustConfigMapName| The name of the ConfigMap to read CA bundle data from.| trusted-ca| |
### coverity-availability-check:0.1 task parameters
|name|description|default value|already set by|
|---|---|---|---|
|AUTH_TOKEN_COVERITY_IMAGE| Name of secret which contains the authentication token for pulling the Coverity image.| auth-token-coverity-image| |
|COV_LICENSE| Name of secret which contains the Coverity license| cov-license| |
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
|shortCommitLength| Length of short commit SHA| 7| |
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
|ACTIVATION_KEY| Name of secret which contains subscription activation key| activation-key| |
|caTrustConfigMapKey| The name of the key in the ConfigMap that contains the CA bundle data.| ca-bundle.crt| |
|caTrustConfigMapName| The name of the ConfigMap to read CA bundle data from.| trusted-ca| |
|config-file-content| Pass configuration to cachi2. Note this needs to be passed as a YAML-formatted config dump, not as a file path! | | |
|dev-package-managers| Enable in-development package managers. WARNING: the behavior may change at any time without notice. Use at your own risk. | false| |
|input| Configures project packages that will have their dependencies prefetched.| None| '$(params.prefetch-input)'|
|log-level| Set cachi2 log level (debug, info, warning, error)| info| |
|sbom-type| Select the SBOM format to generate. Valid values: spdx, cyclonedx.| cyclonedx| |
### sast-coverity-check:0.1 task parameters
|name|description|default value|already set by|
|---|---|---|---|
|AUTH_TOKEN_COVERITY_IMAGE| Name of secret which contains the authentication token for pulling the Coverity image.| auth-token-coverity-image| |
|COV_ANALYZE_ARGS| Arguments to be appended to the cov-analyze command| --enable HARDCODED_CREDENTIALS --security --concurrency --spotbugs-max-mem=4096| |
|COV_LICENSE| Name of secret which contains the Coverity license| cov-license| |
|IMP_FINDINGS_ONLY| Report only important findings. Default is true. To report all findings, specify "false"| true| |
|KFP_GIT_URL| URL from repository to download known false positives files| | |
|PROJECT_NAME| Name of the scanned project, used to find path exclusions. By default, the Konflux component name will be used.| | |
|RECORD_EXCLUDED| Write excluded records in file. Useful for auditing (defaults to false).| false| |
|caTrustConfigMapKey| The name of the key in the ConfigMap that contains the CA bundle data.| ca-bundle.crt| |
|caTrustConfigMapName| The name of the ConfigMap to read CA bundle data from.| trusted-ca| |
|image-digest| Image digest to report findings for.| None| '$(tasks.build-oci-artifact.results.IMAGE_DIGEST)'|
|image-url| Image URL.| None| '$(tasks.build-oci-artifact.results.IMAGE_URL)'|
### sast-shell-check:0.1 task parameters
|name|description|default value|already set by|
|---|---|---|---|
|IMP_FINDINGS_ONLY| Whether to include important findings only| true| |
|KFP_GIT_URL| git repository to download known false positives files from| | |
|PROJECT_NAME| Name of the scanned project, used to find path exclusions. By default, the Konflux component name will be used.| | |
|RECORD_EXCLUDED| Whether to record the excluded findings (default to false). If `true`, the excluded findings will be stored in `excluded-findings.json`. | false| |
|caTrustConfigMapKey| The name of the key in the ConfigMap that contains the CA bundle data.| ca-bundle.crt| |
|caTrustConfigMapName| The name of the ConfigMap to read CA bundle data from.| trusted-ca| |
|image-digest| Image digest to report findings for.| | '$(tasks.build-oci-artifact.results.IMAGE_DIGEST)'|
|image-url| Image URL.| | '$(tasks.build-oci-artifact.results.IMAGE_URL)'|
### sast-snyk-check:0.3 task parameters
|name|description|default value|already set by|
|---|---|---|---|
|ARGS| Append arguments.| | |
|IGNORE_FILE_PATHS| Directories or files to be excluded from Snyk scan (Comma-separated). Useful to split the directories of a git repo across multiple components.| | |
|IMP_FINDINGS_ONLY| Report only important findings. Default is true. To report all findings, specify "false"| true| |
|KFP_GIT_URL| URL from repository to download known false positives files| | |
|PROJECT_NAME| Name of the scanned project, used to find path exclusions. By default, the Konflux component name will be used.| | |
|RECORD_EXCLUDED| Write excluded records in file. Useful for auditing (defaults to false).| false| |
|SNYK_SECRET| Name of secret which contains Snyk token.| snyk-secret| |
|caTrustConfigMapKey| The name of the key in the ConfigMap that contains the CA bundle data.| ca-bundle.crt| |
|caTrustConfigMapName| The name of the ConfigMap to read CA bundle data from.| trusted-ca| |
|image-url| Image URL.| | '$(tasks.build-oci-artifact.results.IMAGE_URL)'|
### sast-unicode-check:0.1 task parameters
|name|description|default value|already set by|
|---|---|---|---|
|FIND_UNICODE_CONTROL_ARGS| arguments for find-unicode-control command.| -p bidi -v -d -t| |
|FIND_UNICODE_CONTROL_GIT_URL| URL from repository to find unicode control.| https://github.com/siddhesh/find-unicode-control.git#c2accbfbba7553a8bc1ebd97089ae08ad8347e58| |
|KFP_GIT_URL| URL from repository to download known false positives files.| | |
|PROJECT_NAME| Name of the scanned project, used to find path exclusions. By default, the Konflux component name will be used.| | |
|RECORD_EXCLUDED| Whether to record the excluded findings (defaults to false). If `true`, the excluded findings will be stored in `excluded-findings.json`. | false| |
|caTrustConfigMapKey| The name of the key in the ConfigMap that contains the CA bundle data.| ca-bundle.crt| |
|caTrustConfigMapName| The name of the ConfigMap to read CA bundle data from.| trusted-ca| |
|image-url| Image URL.| | '$(tasks.build-oci-artifact.results.IMAGE_URL)'|
### show-sbom:0.1 task parameters
|name|description|default value|already set by|
|---|---|---|---|
|CA_TRUST_CONFIG_MAP_KEY| The name of the key in the ConfigMap that contains the CA bundle data.| ca-bundle.crt| |
|CA_TRUST_CONFIG_MAP_NAME| The name of the ConfigMap to read CA bundle data from.| trusted-ca| |
|IMAGE_URL| Fully qualified image name to show SBOM for.| None| '$(tasks.build-oci-artifact.results.IMAGE_URL)'|
|PLATFORM| Specific architecture to display the SBOM for. An example arch would be "linux/amd64". If IMAGE_URL refers to a multi-arch image and this parameter is empty, the task will default to use "linux/amd64".| linux/amd64| |
### summary:0.2 task parameters
|name|description|default value|already set by|
|---|---|---|---|
|build-task-status| State of build task in pipelineRun| Succeeded| '$(tasks.build-oci-artifact.status)'|
|git-url| Git URL| None| '$(tasks.clone-repository.results.url)?rev=$(tasks.clone-repository.results.commit)'|
|image-url| Image URL| None| '$(params.output-image)'|
|pipelinerun-name| pipeline-run to annotate| None| '$(context.pipelineRun.name)'|

## Results
|name|description|value|
|---|---|---|
|CHAINS-GIT_COMMIT| |$(tasks.clone-repository.results.commit)|
|CHAINS-GIT_URL| |$(tasks.clone-repository.results.url)|
|IMAGE_DIGEST| |$(tasks.build-oci-artifact.results.IMAGE_DIGEST)|
|IMAGE_URL| |$(tasks.build-oci-artifact.results.IMAGE_URL)|
## Available results from tasks
### build-maven-zip:0.1 task results
|name|description|used in params (taskname:taskrefversion:taskparam)
|---|---|---|
|IMAGE_DIGEST| Digest of the OCI-Artifact just built| sast-snyk-check:0.3:image-digest ; sast-coverity-check:0.1:image-digest ; coverity-availability-check:0.1:image-digest ; sast-shell-check:0.1:image-digest|
|IMAGE_REF| OCI-Artifact reference of the built OCI-Artifact| |
|IMAGE_URL| OCI-Artifact repository and tag where the built OCI-Artifact was pushed| show-sbom:0.1:IMAGE_URL ; sast-snyk-check:0.3:image-url ; sast-coverity-check:0.1:image-url ; coverity-availability-check:0.1:image-url ; sast-shell-check:0.1:image-url ; sast-unicode-check:0.1:image-url|
|SBOM_BLOB_URL| Reference of SBOM blob digest to enable digest-based verification from provenance| |
### coverity-availability-check:0.1 task results
|name|description|used in params (taskname:taskrefversion:taskparam)
|---|---|---|
|STATUS| Tekton task simple status to be later checked| |
|TEST_OUTPUT| Tekton task result output.| |
### git-clone:0.1 task results
|name|description|used in params (taskname:taskrefversion:taskparam)
|---|---|---|
|CHAINS-GIT_COMMIT| The precise commit SHA that was fetched by this Task. This result uses Chains type hinting to include in the provenance.| |
|CHAINS-GIT_URL| The precise URL that was fetched by this Task. This result uses Chains type hinting to include in the provenance.| |
|commit| The precise commit SHA that was fetched by this Task.| |
|commit-timestamp| The commit timestamp of the checkout| |
|short-commit| The commit SHA that was fetched by this Task limited to params.shortCommitLength number of characters| |
|url| The precise URL that was fetched by this Task.| show-summary:0.2:git-url|
### init:0.2 task results
|name|description|used in params (taskname:taskrefversion:taskparam)
|---|---|---|
|build| Defines if the image in param image-url should be built| |
### sast-coverity-check:0.1 task results
|name|description|used in params (taskname:taskrefversion:taskparam)
|---|---|---|
|TEST_OUTPUT| Tekton task test output.| |
### sast-shell-check:0.1 task results
|name|description|used in params (taskname:taskrefversion:taskparam)
|---|---|---|
|TEST_OUTPUT| Tekton task test output.| |
### sast-snyk-check:0.3 task results
|name|description|used in params (taskname:taskrefversion:taskparam)
|---|---|---|
|TEST_OUTPUT| Tekton task test output.| |
### sast-unicode-check:0.1 task results
|name|description|used in params (taskname:taskrefversion:taskparam)
|---|---|---|
|TEST_OUTPUT| Tekton task test output.| |

## Workspaces
|name|description|optional|used in tasks
|---|---|---|---|
|git-auth| |True| clone-repository:0.1:basic-auth ; prefetch-dependencies:0.1:git-basic-auth|
|netrc| |True| prefetch-dependencies:0.1:netrc|
|workspace| |False| show-summary:0.2:workspace ; clone-repository:0.1:output ; prefetch-dependencies:0.1:source ; build-oci-artifact:0.1:source ; sast-snyk-check:0.3:workspace ; sast-coverity-check:0.1:workspace ; coverity-availability-check:0.1:workspace ; sast-shell-check:0.1:workspace ; sast-unicode-check:0.1:workspace|
## Available workspaces from tasks
### build-maven-zip:0.1 task workspaces
|name|description|optional|workspace from pipeline
|---|---|---|---|
|source| Workspace containing the source code to build.| False| workspace|
### coverity-availability-check:0.1 task workspaces
|name|description|optional|workspace from pipeline
|---|---|---|---|
|workspace| | False| workspace|
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
|netrc| Workspace containing a .netrc file. Cachi2 will use the credentials in this file when performing http(s) requests. | True| netrc|
|source| Workspace with the source code, cachi2 artifacts will be stored on the workspace as well| False| workspace|
### sast-coverity-check:0.1 task workspaces
|name|description|optional|workspace from pipeline
|---|---|---|---|
|workspace| | False| workspace|
### sast-shell-check:0.1 task workspaces
|name|description|optional|workspace from pipeline
|---|---|---|---|
|workspace| | False| workspace|
### sast-snyk-check:0.3 task workspaces
|name|description|optional|workspace from pipeline
|---|---|---|---|
|workspace| | False| workspace|
### sast-unicode-check:0.1 task workspaces
|name|description|optional|workspace from pipeline
|---|---|---|---|
|workspace| | False| workspace|
### summary:0.2 task workspaces
|name|description|optional|workspace from pipeline
|---|---|---|---|
|workspace| The workspace where source code is included.| True| workspace|
