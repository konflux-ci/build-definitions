# "docker-build-rhtap pipeline"

## Parameters
|name|description|default value|used in (taskname:taskrefversion:taskparam)|
|---|---|---|---|
|build-args| Array of --build-arg values ("arg=value" strings) for buildah| []| build-container:0.1:BUILD_ARGS|
|build-args-file| Path to a file with build arguments for buildah, see https://www.mankier.com/1/buildah-build#--build-arg-file| | build-container:0.1:BUILD_ARGS_FILE|
|dockerfile| Path to the Dockerfile inside the context specified by parameter path-context| Dockerfile| build-container:0.1:DOCKERFILE|
|event-type| Event that triggered the pipeline run, e.g. push, pull_request| push| |
|git-url| Source Repository URL| None| clone-repository:0.1:url ; acs-deploy-check:0.1:gitops-repo-url ; update-deployment:0.1:gitops-repo-url|
|gitops-auth-secret-name| Secret name to enable this pipeline to update the gitops repo with the new image. | gitops-auth-secret| update-deployment:0.1:gitops-auth-secret-name|
|image-expires-after| Image tag expiration time, time values could be something like 1h, 2d, 3w for hours, days, and weeks, respectively.| | build-container:0.1:IMAGE_EXPIRES_AFTER|
|output-image| Fully Qualified Output Image| None| show-summary:0.2:image-url ; init:0.2:image-url ; build-container:0.1:IMAGE ; acs-image-check:0.1:image ; acs-image-scan:0.1:image|
|path-context| Path to the source code of an application's component from where to build image.| .| build-container:0.1:CONTEXT|
|rebuild| Force rebuild image| false| init:0.2:rebuild|
|revision| Revision of the Source Repository| | clone-repository:0.1:revision|
|stackrox-secret| | rox-api-token| acs-image-check:0.1:rox-secret-name ; acs-image-scan:0.1:rox-secret-name ; acs-deploy-check:0.1:rox-secret-name|

## Available params from tasks
### acs-deploy-check:0.1 task parameters
|name|description|default value|already set by|
|---|---|---|---|
|gitops-auth-secret-name| Secret of basic-auth type containing credentials to clone the gitops repository. | gitops-auth-secret| |
|gitops-repo-url| URL of gitops repository to check.| None| '$(params.git-url)-gitops'|
|insecure-skip-tls-verify| When set to `"true"`, skip verifying the TLS certs of the Central endpoint. Defaults to `"false"`. | false| 'true'|
|rox-secret-name| Secret containing the StackRox server endpoint and API token with CI permissions under rox-api-endpoint and rox-api-token keys. For example: rox-api-endpoint: rox.stackrox.io:443 ; rox-api-token: eyJhbGciOiJS... | None| '$(params.stackrox-secret)'|
|verbose| | true| |
### acs-image-check:0.1 task parameters
|name|description|default value|already set by|
|---|---|---|---|
|image| Full name of image to scan (example -- gcr.io/rox/sample:5.0-rc1) | None| '$(params.output-image)'|
|image-digest| Digest of the image | None| '$(tasks.build-container.results.IMAGE_DIGEST)'|
|insecure-skip-tls-verify| When set to `"true"`, skip verifying the TLS certs of the Central endpoint.  Defaults to `"false"`. | false| 'true'|
|rox-secret-name| Secret containing the StackRox server endpoint and API token with CI permissions under rox-api-endpoint and rox-api-token keys. For example: rox-api-endpoint: rox.stackrox.io:443 ; rox-api-token: eyJhbGciOiJS... | None| '$(params.stackrox-secret)'|
### acs-image-scan:0.1 task parameters
|name|description|default value|already set by|
|---|---|---|---|
|image| Full name of image to scan (example -- gcr.io/rox/sample:5.0-rc1) | None| '$(params.output-image)'|
|image-digest| Digest of the image to scan | None| '$(tasks.build-container.results.IMAGE_DIGEST)'|
|insecure-skip-tls-verify| When set to `"true"`, skip verifying the TLS certs of the Central endpoint.  Defaults to `"false"`. | false| 'true'|
|rox-secret-name| Secret containing the StackRox server endpoint and API token with CI permissions under rox-api-endpoint and rox-api-token keys. For example: rox-api-endpoint: rox.stackrox.io:443 ; rox-api-token: eyJhbGciOiJS... | None| '$(params.stackrox-secret)'|
### buildah-rhtap:0.1 task parameters
|name|description|default value|already set by|
|---|---|---|---|
|BUILD_ARGS| Array of --build-arg values ("arg=value" strings)| []| '['$(params.build-args[*])']'|
|BUILD_ARGS_FILE| Path to a file with build arguments, see https://www.mankier.com/1/buildah-build#--build-arg-file| | '$(params.build-args-file)'|
|CONTEXT| Path to the directory to use as context.| .| '$(params.path-context)'|
|DOCKERFILE| Path to the Dockerfile to build.| ./Dockerfile| '$(params.dockerfile)'|
|IMAGE| Reference of the image buildah will produce.| None| '$(params.output-image)'|
|STORAGE_DRIVER| Storage driver to configure for buildah| vfs| |
|TLSVERIFY| Verify the TLS on the registry endpoint (for push/pull to a non-TLS registry)| true| |
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
|skip-checks| Skip checks against built image| false| |
### rpms-signature-scan:0.1 task parameters
|name|description|default value|already set by|
|---|---|---|---|
|ca-trust-config-map-key| The name of the key in the ConfigMap that contains the CA bundle data.| ca-bundle.crt| |
|ca-trust-config-map-name| The name of the ConfigMap to read CA bundle data from.| trusted-ca| |
|fail-unsigned| [true \ false] If true fail if unsigned RPMs were found| false| |
|image-digest| Image digest to scan| None| '$(tasks.build-container.results.IMAGE_DIGEST)'|
|image-url| Image URL| None| '$(tasks.build-container.results.IMAGE_URL)'|
|workdir| Directory that will be used for storing temporary files produced by this task. | /tmp| |
### show-sbom-rhdh:0.1 task parameters
|name|description|default value|already set by|
|---|---|---|---|
|IMAGE_URL| Fully qualified image name to show SBOM for.| None| '$(tasks.build-container.results.IMAGE_URL)'|
### summary:0.2 task parameters
|name|description|default value|already set by|
|---|---|---|---|
|build-task-status| State of build task in pipelineRun| Succeeded| '$(tasks.build-container.status)'|
|git-url| Git URL| None| '$(tasks.clone-repository.results.url)?rev=$(tasks.clone-repository.results.commit)'|
|image-url| Image URL| None| '$(params.output-image)'|
|pipelinerun-name| pipeline-run to annotate| None| '$(context.pipelineRun.name)'|
### update-deployment:0.1 task parameters
|name|description|default value|already set by|
|---|---|---|---|
|gitops-auth-secret-name| Secret of basic-auth type containing credentials to commit into gitops repository. | gitops-auth-secret| '$(params.gitops-auth-secret-name)'|
|gitops-repo-url| URL of gitops repository to update with the newly built image.| None| '$(params.git-url)-gitops'|
|image| Reference of the newly built image to use.| None| '$(tasks.build-container.results.IMAGE_URL)@$(tasks.build-container.results.IMAGE_DIGEST)'|

## Results
|name|description|value|
|---|---|---|
|ACS_SCAN_OUTPUT| |$(tasks.acs-image-scan.results.SCAN_OUTPUT)|
|CHAINS-GIT_COMMIT| |$(tasks.clone-repository.results.commit)|
|CHAINS-GIT_URL| |$(tasks.clone-repository.results.url)|
|IMAGE_DIGEST| |$(tasks.build-container.results.IMAGE_DIGEST)|
|IMAGE_URL| |$(tasks.build-container.results.IMAGE_URL)|
## Available results from tasks
### acs-image-scan:0.1 task results
|name|description|used in params (taskname:taskrefversion:taskparam)
|---|---|---|
|SCAN_OUTPUT| Summary of the roxctl scan| |
|TEST_OUTPUT| Result of the `roxctl image scan` check| |
### buildah-rhtap:0.1 task results
|name|description|used in params (taskname:taskrefversion:taskparam)
|---|---|---|
|BASE_IMAGES_DIGESTS| Digests of the base images used for build| |
|IMAGE_DIGEST| Digest of the image just built| rpms-signature-scan:0.1:image-digest ; acs-image-check:0.1:image-digest ; acs-image-scan:0.1:image-digest|
|IMAGE_URL| Image repository and tag where the built image was pushed| show-sbom:0.1:IMAGE_URL ; rpms-signature-scan:0.1:image-url ; update-deployment:0.1:image|
|SBOM_BLOB_URL| Link to the SBOM layer pushed to the registry as part of an OCI artifact.| |
### git-clone:0.1 task results
|name|description|used in params (taskname:taskrefversion:taskparam)
|---|---|---|
|commit| The precise commit SHA that was fetched by this Task.| build-container:0.1:COMMIT_SHA|
|commit-timestamp| The commit timestamp of the checkout| |
|short-commit| The commit SHA that was fetched by this Task limited to params.shortCommitLength number of characters| |
|url| The precise URL that was fetched by this Task.| show-summary:0.2:git-url|
### init:0.2 task results
|name|description|used in params (taskname:taskrefversion:taskparam)
|---|---|---|
|build| Defines if the image in param image-url should be built| |
### rpms-signature-scan:0.1 task results
|name|description|used in params (taskname:taskrefversion:taskparam)
|---|---|---|
|IMAGES_PROCESSED| Images processed in the task.| |
|RPMS_DATA| Information about signed and unsigned RPMs| |
|TEST_OUTPUT| Tekton task test output.| |
### show-sbom-rhdh:0.1 task results
|name|description|used in params (taskname:taskrefversion:taskparam)
|---|---|---|
|LINK_TO_SBOM| Placeholder result meant to make RHDH identify this task as the producer of the SBOM logs.| |

## Workspaces
|name|description|optional|used in tasks
|---|---|---|---|
|git-auth| |True| clone-repository:0.1:basic-auth|
|workspace| |False| show-summary:0.2:workspace ; clone-repository:0.1:output ; build-container:0.1:source|
## Available workspaces from tasks
### acs-deploy-check:0.1 task workspaces
|name|description|optional|workspace from pipeline
|---|---|---|---|
|gitops-auth| | True| |
### buildah-rhtap:0.1 task workspaces
|name|description|optional|workspace from pipeline
|---|---|---|---|
|source| Workspace containing the source code to build.| False| workspace|
### git-clone:0.1 task workspaces
|name|description|optional|workspace from pipeline
|---|---|---|---|
|basic-auth| A Workspace containing a .gitconfig and .git-credentials file or username and password. These will be copied to the user's home before any git commands are run. Any other files in this Workspace are ignored. It is strongly recommended to use ssh-directory over basic-auth whenever possible and to bind a Secret to this Workspace over other volume types. | True| git-auth|
|output| The git repo will be cloned onto the volume backing this Workspace.| False| workspace|
|ssh-directory| A .ssh directory with private key, known_hosts, config, etc. Copied to the user's home before git commands are executed. Used to authenticate with the git remote when performing the clone. Binding a Secret to this Workspace is strongly recommended over other volume types. | True| |
### summary:0.2 task workspaces
|name|description|optional|workspace from pipeline
|---|---|---|---|
|workspace| The workspace where source code is included.| True| workspace|
### update-deployment:0.1 task workspaces
|name|description|optional|workspace from pipeline
|---|---|---|---|
|gitops-auth| | True| |
