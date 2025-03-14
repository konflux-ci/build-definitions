# "gitops-pull-request pipeline"

## Parameters
|name|description|default value|used in (taskname:taskrefversion:taskparam)|
|---|---|---|---|
|ec-policy-configuration| Enterprise Contract policy to validate against| github.com/enterprise-contract/config//default| verify-enterprise-contract:0.1:POLICY_CONFIGURATION|
|ec-public-key| The public key that EC should use to verify signatures| k8s://$(context.pipelineRun.namespace)/cosign-pub| verify-enterprise-contract:0.1:PUBLIC_KEY ; download-sboms:0.1:PUBLIC_KEY|
|ec-rekor-host| The Rekor host that EC should use to look up transparency logs| http://rekor-server.rhtap-tas.svc| verify-enterprise-contract:0.1:REKOR_HOST ; download-sboms:0.1:REKOR_HOST|
|ec-strict| Should EC violations cause the pipeline to fail?| true| verify-enterprise-contract:0.1:STRICT|
|ec-tuf-mirror| The TUF mirror that EC should use| http://tuf.rhtap-tas.svc| verify-enterprise-contract:0.1:TUF_MIRROR ; download-sboms:0.1:TUF_MIRROR|
|fail-if-trustification-not-configured| Should the pipeline fail when there are SBOMs to upload but Trustification is not properly configured (i.e. the secret is missing or doesn't have all the required keys)?| true| upload-sboms-to-trustification:0.1:FAIL_IF_TRUSTIFICATION_NOT_CONFIGURED|
|git-url| Gitops repo url| None| clone-repository:0.1:url|
|revision| Gitops repo revision| | clone-repository:0.1:revision|
|target-branch| The target branch for the pull request| main| get-images-to-verify:0.1:TARGET_BRANCH ; get-images-to-upload-sbom:0.1:TARGET_BRANCH|
|trustification-secret-name| The name of the Secret that contains Trustification (TPA) configuration| tpa-secret| upload-sboms-to-trustification:0.1:TRUSTIFICATION_SECRET_NAME|

## Available params from tasks
### download-sbom-from-url-in-attestation:0.1 task parameters
|name|description|default value|already set by|
|---|---|---|---|
|HTTP_RETRIES| Maximum number of retries for transient HTTP(S) errors| 3| |
|IGNORE_REKOR| Skip Rekor transparency log checks during validation.| false| |
|IMAGES| JSON object containing the array of images whose SBOMs should be downloaded. See the description for more details.| None| '$(tasks.get-images-to-upload-sbom.results.IMAGES_TO_VERIFY)'|
|PUBLIC_KEY| Public key used to verify signatures. Must be a valid k8s cosign reference, e.g. k8s://my-space/my-secret where my-secret contains the expected cosign.pub attribute.| | '$(params.ec-public-key)'|
|REKOR_HOST| Rekor host for transparency log lookups| | '$(params.ec-rekor-host)'|
|SBOMS_DIR| Path to directory (relative to the 'sboms' workspace) where SBOMs should be downloaded.| .| 'sboms'|
|TUF_MIRROR| TUF mirror URL. Provide a value when NOT using public sigstore deployment.| | '$(params.ec-tuf-mirror)'|
### gather-deploy-images:0.1 task parameters
|name|description|default value|already set by|
|---|---|---|---|
|ENVIRONMENTS| Gather images from the manifest files for the specified environments| ['development', 'stage', 'prod']| |
|TARGET_BRANCH| If specified, will gather only the images that changed between the current revision and the target branch. Useful for pull requests. Note that the repository cloned on the source workspace must already contain the origin/$TARGET_BRANCH reference. | | '$(params.target-branch)'|
### gather-deploy-images:0.1 task parameters
|name|description|default value|already set by|
|---|---|---|---|
|ENVIRONMENTS| Gather images from the manifest files for the specified environments| ['development', 'stage', 'prod']| |
|TARGET_BRANCH| If specified, will gather only the images that changed between the current revision and the target branch. Useful for pull requests. Note that the repository cloned on the source workspace must already contain the origin/$TARGET_BRANCH reference. | | '$(params.target-branch)'|
### git-clone:0.1 task parameters
|name|description|default value|already set by|
|---|---|---|---|
|caTrustConfigMapKey| The name of the key in the ConfigMap that contains the CA bundle data.| ca-bundle.crt| |
|caTrustConfigMapName| The name of the ConfigMap to read CA bundle data from.| trusted-ca| |
|deleteExisting| Clean out the contents of the destination directory if it already exists before cloning.| true| |
|depth| Perform a shallow clone, fetching only the most recent N commits.| 1| |
|enableSymlinkCheck| Check symlinks in the repo. If they're pointing outside of the repo, the build will fail. | true| |
|fetchTags| Fetch all tags for the repo.| false| 'true'|
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
### upload-sbom-to-trustification:0.1 task parameters
|name|description|default value|already set by|
|---|---|---|---|
|FAIL_IF_TRUSTIFICATION_NOT_CONFIGURED| Should the task fail if the Secret does not contain the required keys? (Set "true" to fail, "false" to skip uploading and exit with success).| true| '$(params.fail-if-trustification-not-configured)'|
|HTTP_RETRIES| Maximum number of retries for transient HTTP(S) errors| 3| |
|SBOMS_DIR| Directory containing SBOM files. The task will search for CycloneDX JSON SBOMs recursively in this directory and upload them all to Trustification. The path is relative to the 'sboms' workspace.| .| 'sboms'|
|TRUSTIFICATION_SECRET_NAME| Name of the Secret containing auth and configuration| trustification-secret| '$(params.trustification-secret-name)'|
### verify-enterprise-contract:0.1 task parameters
|name|description|default value|already set by|
|---|---|---|---|
|CA_TRUST_CONFIGMAP_NAME| The name of the ConfigMap to read CA bundle data from.| trusted-ca| |
|CA_TRUST_CONFIG_MAP_KEY| The name of the key in the ConfigMap that contains the CA bundle data.| ca-bundle.crt| |
|EFFECTIVE_TIME| Run policy checks with the provided time.| now| |
|EXTRA_RULE_DATA| Merge additional Rego variables into the policy data. Use syntax "key=value,key2=value2..."| | |
|HOMEDIR| Value for the HOME environment variable.| /tekton/home| |
|IGNORE_REKOR| Skip Rekor transparency log checks during validation.| false| |
|IMAGES| Spec section of an ApplicationSnapshot resource. Not all fields of the resource are required. A minimal example:  ```json   {     "components": [       {         "containerImage": "quay.io/example/repo:latest"       }     ]   } ```  Each `containerImage` in the `components` array is validated. | None| '$(tasks.get-images-to-verify.results.IMAGES_TO_VERIFY)'|
|INFO| Include rule titles and descriptions in the output. Set to `"false"` to disable it.| true| |
|POLICY_CONFIGURATION| Name of the policy configuration (EnterpriseContractPolicy resource) to use. `namespace/name` or `name` syntax supported. If namespace is omitted the namespace where the task runs is used. You can also specify a policy configuration using a git url, e.g. `github.com/enterprise-contract/config//slsa3`. | enterprise-contract-service/default| '$(params.ec-policy-configuration)'|
|PUBLIC_KEY| Public key used to verify signatures. Must be a valid k8s cosign reference, e.g. k8s://my-space/my-secret where my-secret contains the expected cosign.pub attribute.| | '$(params.ec-public-key)'|
|REKOR_HOST| Rekor host for transparency log lookups| | '$(params.ec-rekor-host)'|
|SINGLE_COMPONENT| Reduce the Snapshot to only the component whose build caused the Snapshot to be created| false| |
|SINGLE_COMPONENT_CUSTOM_RESOURCE| Name, including kind, of the Kubernetes resource to query for labels when single component mode is enabled, e.g. pr/somepipeline. | unknown| |
|SINGLE_COMPONENT_CUSTOM_RESOURCE_NS| Kubernetes namespace where the SINGLE_COMPONENT_NAME is found. Only used when single component mode is enabled. | | |
|SSL_CERT_DIR| Path to a directory containing SSL certs to be used when communicating with external services. This is useful when using the integrated registry and a local instance of Rekor on a development cluster which may use certificates issued by a not-commonly trusted root CA. In such cases, `/var/run/secrets/kubernetes.io/serviceaccount` is a good value. Multiple paths can be provided by using the `:` separator. | | |
|STRICT| Fail the task if policy fails. Set to `"false"` to disable it.| true| '$(params.ec-strict)'|
|TIMEOUT| This param is deprecated and will be removed in future. Its value is ignored. EC will be run without a timeout. (If you do want to apply a timeout use the Tekton task timeout.) | | |
|TUF_MIRROR| TUF mirror URL. Provide a value when NOT using public sigstore deployment.| | '$(params.ec-tuf-mirror)'|
|WORKERS| Number of parallel workers to use for policy evaluation.| 1| |

## Results
|name|description|value|
|---|---|---|
## Available results from tasks
### gather-deploy-images:0.1 task results
|name|description|used in params (taskname:taskrefversion:taskparam)
|---|---|---|
|IMAGES_TO_VERIFY| The images to be verified, in a format compatible with https://github.com/konflux-ci/build-definitions/tree/main/task/verify-enterprise-contract/0.1. When there are no images to verify, this is an empty string. | verify-enterprise-contract:0.1:IMAGES|
### gather-deploy-images:0.1 task results
|name|description|used in params (taskname:taskrefversion:taskparam)
|---|---|---|
|IMAGES_TO_VERIFY| The images to be verified, in a format compatible with https://github.com/konflux-ci/build-definitions/tree/main/task/verify-enterprise-contract/0.1. When there are no images to verify, this is an empty string. | download-sboms:0.1:IMAGES|
### git-clone:0.1 task results
|name|description|used in params (taskname:taskrefversion:taskparam)
|---|---|---|
|CHAINS-GIT_COMMIT| The precise commit SHA that was fetched by this Task. This result uses Chains type hinting to include in the provenance.| |
|CHAINS-GIT_URL| The precise URL that was fetched by this Task. This result uses Chains type hinting to include in the provenance.| |
|commit| The precise commit SHA that was fetched by this Task.| |
|commit-timestamp| The commit timestamp of the checkout| |
|short-commit| The commit SHA that was fetched by this Task limited to params.shortCommitLength number of characters| |
|url| The precise URL that was fetched by this Task.| |
### verify-enterprise-contract:0.1 task results
|name|description|used in params (taskname:taskrefversion:taskparam)
|---|---|---|
|TEST_OUTPUT| Short summary of the policy evaluation for each image| |

## Workspaces
|name|description|optional|used in tasks
|---|---|---|---|
## Available workspaces from tasks
### download-sbom-from-url-in-attestation:0.1 task workspaces
|name|description|optional|workspace from pipeline
|---|---|---|---|
|sboms| SBOMs will be downloaded to (a subdirectory of) this workspace.| False| workspace|
### gather-deploy-images:0.1 task workspaces
|name|description|optional|workspace from pipeline
|---|---|---|---|
|source| Should contain a cloned gitops repo at the ./source subpath| False| workspace|
### gather-deploy-images:0.1 task workspaces
|name|description|optional|workspace from pipeline
|---|---|---|---|
|source| Should contain a cloned gitops repo at the ./source subpath| False| workspace|
### git-clone:0.1 task workspaces
|name|description|optional|workspace from pipeline
|---|---|---|---|
|basic-auth| A Workspace containing a .gitconfig and .git-credentials file or username and password. These will be copied to the user's home before any git commands are run. Any other files in this Workspace are ignored. It is strongly recommended to use ssh-directory over basic-auth whenever possible and to bind a Secret to this Workspace over other volume types. | True| git-auth|
|output| The git repo will be cloned onto the volume backing this Workspace.| False| workspace|
|ssh-directory| A .ssh directory with private key, known_hosts, config, etc. Copied to the user's home before git commands are executed. Used to authenticate with the git remote when performing the clone. Binding a Secret to this Workspace is strongly recommended over other volume types. | True| |
### upload-sbom-to-trustification:0.1 task workspaces
|name|description|optional|workspace from pipeline
|---|---|---|---|
|sboms| Directory containing the SBOMs to upload| False| workspace|
### verify-enterprise-contract:0.1 task workspaces
|name|description|optional|workspace from pipeline
|---|---|---|---|
|data| The workspace where the snapshot spec json file resides| True| |
