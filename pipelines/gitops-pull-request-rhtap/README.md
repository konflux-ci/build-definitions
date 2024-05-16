# "gitops-pull-request pipeline"
## Parameters
|name|description|default value|used in (taskname:taskrefversion:taskparam)|
|---|---|---|---|
|ec-policy-configuration| Enterprise Contract policy to validate against| github.com/enterprise-contract/config//default| verify-enteprise-contract:0.1:POLICY_CONFIGURATION|
|ec-public-key| The public key that EC should use to verify signatures| k8s://$(context.pipelineRun.namespace)/cosign-pub| verify-enteprise-contract:0.1:PUBLIC_KEY|
|ec-rekor-host| The Rekor host that EC should use to look up transparency logs| http://rekor-server.rhtap.svc| verify-enteprise-contract:0.1:REKOR_HOST|
|ec-strict| Should EC violations cause the pipeline to fail?| true| verify-enteprise-contract:0.1:STRICT|
|ec-tuf-mirror| The TUF mirror that EC should use| http://tuf.rhtap.svc| verify-enteprise-contract:0.1:TUF_MIRROR|
|git-url| Gitops repo url| None| clone-repository:0.1:url|
|revision| Gitops repo revision| | clone-repository:0.1:revision|
|target-branch| The target branch for the pull request| main| gather-deploy-images:0.1:TARGET_BRANCH|
## Available params from tasks
### gather-deploy-images:0.1 task parameters
|name|description|default value|already set by|
|---|---|---|---|
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
|sparseCheckoutDirectories| Define the directory patterns to match or exclude when performing a sparse checkout.| | |
|sslVerify| Set the `http.sslVerify` global git config. Setting this to `false` is not advised unless you are sure that you trust your git remote.| true| |
|subdirectory| Subdirectory inside the `output` Workspace to clone the repo into.| source| |
|submodules| Initialize and fetch git submodules.| true| |
|url| Repository URL to clone from.| None| '$(params.git-url)'|
|userHome| Absolute path to the user's home directory. Set this explicitly if you are running the image as a non-root user. | /tekton/home| |
|verbose| Log the commands that are executed during `git-clone`'s operation.| false| |
### verify-enterprise-contract:0.1 task parameters
|name|description|default value|already set by|
|---|---|---|---|
|EFFECTIVE_TIME| Run policy checks with the provided time.| now| |
|HOMEDIR| Value for the HOME environment variable.| /tekton/home| |
|IGNORE_REKOR| Skip Rekor transparency log checks during validation.| false| |
|IMAGES| Spec section of an ApplicationSnapshot resource. Not all fields of the resource are required. A minimal example:   {     "components": [       {         "containerImage": "quay.io/example/repo:latest"       }     ]   } Each "containerImage" in the "components" array is validated. | None| '$(tasks.gather-deploy-images.results.IMAGES_TO_VERIFY)'|
|INFO| Include rule titles and descriptions in the output. Set to "false" to disable it.| true| |
|POLICY_CONFIGURATION| Name of the policy configuration (EnterpriseContractPolicy resource) to use. `namespace/name` or `name` syntax supported. If namespace is omitted the namespace where the task runs is used. | enterprise-contract-service/default| '$(params.ec-policy-configuration)'|
|PUBLIC_KEY| Public key used to verify signatures. Must be a valid k8s cosign reference, e.g. k8s://my-space/my-secret where my-secret contains the expected cosign.pub attribute.| | '$(params.ec-public-key)'|
|REKOR_HOST| Rekor host for transparency log lookups| | '$(params.ec-rekor-host)'|
|SSL_CERT_DIR| Path to a directory containing SSL certs to be used when communicating with external services. This is useful when using the integrated registry and a local instance of Rekor on a development cluster which may use certificates issued by a not-commonly trusted root CA. In such cases, "/var/run/secrets/kubernetes.io/serviceaccount" is a good value. Multiple paths can be provided by using the ":" separator. | | |
|STRICT| Fail the task if policy fails. Set to "false" to disable it.| true| '$(params.ec-strict)'|
|TUF_MIRROR| TUF mirror URL. Provide a value when NOT using public sigstore deployment.| | '$(params.ec-tuf-mirror)'|

## Results
|name|description|value|
|---|---|---|
## Available results from tasks
### gather-deploy-images:0.1 task results
|name|description|used in params (taskname:taskrefversion:taskparam)
|---|---|---|
|IMAGES_TO_VERIFY| The images to be verified, in a format compatible with https://github.com/konflux-ci/build-definitions/tree/main/task/verify-enterprise-contract/0.1. When there are no images to verify, this is an empty string. | verify-enteprise-contract:0.1:IMAGES|
### git-clone:0.1 task results
|name|description|used in params (taskname:taskrefversion:taskparam)
|---|---|---|
|commit| The precise commit SHA that was fetched by this Task.| |
|url| The precise URL that was fetched by this Task.| |
### verify-enterprise-contract:0.1 task results
|name|description|used in params (taskname:taskrefversion:taskparam)
|---|---|---|
|TEST_OUTPUT| Short summary of the policy evaluation for each image| |

## Workspaces
|name|description|optional|used in tasks
|---|---|---|---|
## Available workspaces from tasks
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
### verify-enterprise-contract:0.1 task workspaces
|name|description|optional|workspace from pipeline
|---|---|---|---|
|data| The workspace where the snapshot spec json file resides| True| |
