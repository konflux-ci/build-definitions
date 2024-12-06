# "maven-zip-build-oci-ta pipeline"
This pipeline will build the maven zip to oci-artifact while maintaining trust after pipeline customization.

_Uses `prefetch-dependencies` to fetch all artifacts which will be the content of the maven zip, and then uses `build-maven-zip-oci-ta` to create zip and push it to quay.io as oci-artifact. Information is shared between tasks using OCI artifacts instead of PVCs.
This pipeline is pushed as a Tekton bundle to [quay.io](https://quay.io/repository/konflux-ci/tekton-catalog/pipeline-maven-zip-build-oci-ta?tab=tags)_

## Parameters
|name|description|default value|used in (taskname:taskrefversion:taskparam)|
|---|---|---|---|
|git-url| Source Repository URL| None| clone-repository:0.1:url|
|image-expires-after| Image tag expiration time, time values could be something like 1h, 2d, 3w for hours, days, and weeks, respectively.| | clone-repository:0.1:ociArtifactExpiresAfter ; prefetch-dependencies:0.1:ociArtifactExpiresAfter ; build-oci-artifact:0.1:IMAGE_EXPIRES_AFTER|
|output-image| Fully Qualified Output Image| None| init:0.2:image-url ; clone-repository:0.1:ociStorage ; prefetch-dependencies:0.1:ociStorage ; build-oci-artifact:0.1:IMAGE|
|prefetch-input| Build dependencies to be prefetched by Cachi2| generic| prefetch-dependencies:0.1:input|
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
### prefetch-dependencies-oci-ta:0.1 task parameters
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
### push-dockerfile:0.1 task parameters
|name|description|default value|already set by|
|---|---|---|---|
|ARTIFACT_TYPE| Artifact type of the Dockerfile image.| application/vnd.konflux.dockerfile| |
|CONTEXT| Path to the directory to use as context.| .| '$(params.path-context)'|
|DOCKERFILE| Path to the Dockerfile.| ./Dockerfile| '$(params.dockerfile)'|
|IMAGE| The built binary image. The Dockerfile is pushed to the same image repository alongside.| None| '$(tasks.build-image-index.results.IMAGE_URL)'|
|IMAGE_DIGEST| The built binary image digest, which is used to construct the tag of Dockerfile image.| None| '$(tasks.build-image-index.results.IMAGE_DIGEST)'|
|TAG_SUFFIX| Suffix of the Dockerfile image tag.| .dockerfile| |
### rpms-signature-scan:0.2 task parameters
|name|description|default value|already set by|
|---|---|---|---|
|ca-trust-config-map-key| The name of the key in the ConfigMap that contains the CA bundle data.| ca-bundle.crt| |
|ca-trust-config-map-name| The name of the ConfigMap to read CA bundle data from.| trusted-ca| |
|image-digest| Image digest to scan| None| '$(tasks.build-image-index.results.IMAGE_DIGEST)'|
|image-url| Image URL| None| '$(tasks.build-image-index.results.IMAGE_URL)'|
|workdir| Directory that will be used for storing temporary files produced by this task. | /tmp| |
### sast-snyk-check-oci-ta:0.3 task parameters
|name|description|default value|already set by|
|---|---|---|---|
|ARGS| Append arguments.| | |
|CACHI2_ARTIFACT| The Trusted Artifact URI pointing to the artifact with the prefetched dependencies.| | '$(tasks.prefetch-dependencies.results.CACHI2_ARTIFACT)'|
|IMP_FINDINGS_ONLY| Report only important findings. Default is true. To report all findings, specify "false"| true| |
|KFP_GIT_URL| URL from repository to download known false positives files| | |
|PROJECT_NAME| Name of the scanned project, used to find path exclusions. By default, the Konflux component name will be used.| | |
|RECORD_EXCLUDED| Write excluded records in file. Useful for auditing (defaults to false).| false| |
|SNYK_SECRET| Name of secret which contains Snyk token.| snyk-secret| |
|SOURCE_ARTIFACT| The Trusted Artifact URI pointing to the artifact with the application source code.| None| '$(tasks.prefetch-dependencies.results.SOURCE_ARTIFACT)'|
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
|image-url| Image URL.| | '$(tasks.build-image-index.results.IMAGE_URL)'|
### show-sbom:0.1 task parameters
|name|description|default value|already set by|
|---|---|---|---|
|CA_TRUST_CONFIG_MAP_KEY| The name of the key in the ConfigMap that contains the CA bundle data.| ca-bundle.crt| |
|CA_TRUST_CONFIG_MAP_NAME| The name of the ConfigMap to read CA bundle data from.| trusted-ca| |
|IMAGE_URL| Fully qualified image name to show SBOM for.| None| '$(tasks.build-oci-artifact.results.IMAGE_URL)'|
|PLATFORM| Specific architecture to display the SBOM for. An example arch would be "linux/amd64". If IMAGE_URL refers to a multi-arch image and this parameter is empty, the task will default to use "linux/amd64".| linux/amd64| |

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
|IMAGE_DIGEST| Digest of the OCI-Artifact just built| sast-snyk-check:0.3:image-digest|
|IMAGE_REF| OCI-Artifact reference of the built OCI-Artifact| |
|IMAGE_URL| OCI-Artifact repository and tag where the built OCI-Artifact was pushed| show-sbom:0.1:IMAGE_URL ; sast-snyk-check:0.3:image-url|
|SBOM_BLOB_URL| Reference of SBOM blob digest to enable digest-based verification from provenance| |
### git-clone-oci-ta:0.1 task results
|name|description|used in params (taskname:taskrefversion:taskparam)
|---|---|---|
|CHAINS-GIT_COMMIT| The precise commit SHA that was fetched by this Task. This result uses Chains type hinting to include in the provenance.| |
|CHAINS-GIT_URL| The precise URL that was fetched by this Task. This result uses Chains type hinting to include in the provenance.| |
|SOURCE_ARTIFACT| The Trusted Artifact URI pointing to the artifact with the application source code.| prefetch-dependencies:0.1:SOURCE_ARTIFACT|
|commit| The precise commit SHA that was fetched by this Task.| |
|commit-timestamp| The commit timestamp of the checkout| |
|short-commit| The commit SHA that was fetched by this Task limited to params.shortCommitLength number of characters| |
|url| The precise URL that was fetched by this Task.| |
### init:0.2 task results
|name|description|used in params (taskname:taskrefversion:taskparam)
|---|---|---|
|build| Defines if the image in param image-url should be built| |
### prefetch-dependencies-oci-ta:0.1 task results
|name|description|used in params (taskname:taskrefversion:taskparam)
|---|---|---|
|CACHI2_ARTIFACT| The Trusted Artifact URI pointing to the artifact with the prefetched dependencies.| build-oci-artifact:0.1:CACHI2_ARTIFACT ; sast-snyk-check:0.3:CACHI2_ARTIFACT|
|SOURCE_ARTIFACT| The Trusted Artifact URI pointing to the artifact with the application source code.| sast-snyk-check:0.3:SOURCE_ARTIFACT|
### push-dockerfile:0.1 task results
|name|description|used in params (taskname:taskrefversion:taskparam)
|---|---|---|
|IMAGE_REF| Digest-pinned image reference to the Dockerfile image.| |
### rpms-signature-scan:0.2 task results
|name|description|used in params (taskname:taskrefversion:taskparam)
|---|---|---|
|IMAGES_PROCESSED| Images processed in the task.| |
|RPMS_DATA| Information about signed and unsigned RPMs| |
|TEST_OUTPUT| Tekton task test output.| |
### sast-snyk-check-oci-ta:0.3 task results
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
|workspace| |False| sast-unicode-check:0.1:workspace ; push-dockerfile:0.1:workspace|
## Available workspaces from tasks
### git-clone-oci-ta:0.1 task workspaces
|name|description|optional|workspace from pipeline
|---|---|---|---|
|basic-auth| A Workspace containing a .gitconfig and .git-credentials file or username and password. These will be copied to the user's home before any git commands are run. Any other files in this Workspace are ignored. It is strongly recommended to use ssh-directory over basic-auth whenever possible and to bind a Secret to this Workspace over other volume types. | True| git-auth|
|ssh-directory| A .ssh directory with private key, known_hosts, config, etc. Copied to the user's home before git commands are executed. Used to authenticate with the git remote when performing the clone. Binding a Secret to this Workspace is strongly recommended over other volume types. | True| |
### prefetch-dependencies-oci-ta:0.1 task workspaces
|name|description|optional|workspace from pipeline
|---|---|---|---|
|git-basic-auth| A Workspace containing a .gitconfig and .git-credentials file or username and password. These will be copied to the user's home before any cachi2 commands are run. Any other files in this Workspace are ignored. It is strongly recommended to bind a Secret to this Workspace over other volume types. | True| git-auth|
|netrc| Workspace containing a .netrc file. Cachi2 will use the credentials in this file when performing http(s) requests. | True| netrc|
### push-dockerfile:0.1 task workspaces
|name|description|optional|workspace from pipeline
|---|---|---|---|
|workspace| Workspace containing the source code from where the Dockerfile is discovered.| False| workspace|
### sast-unicode-check:0.1 task workspaces
|name|description|optional|workspace from pipeline
|---|---|---|---|
|workspace| | False| workspace|
