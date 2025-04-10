# git-clone task

The git-clone Task will clone a repo from the provided url into the output Workspace. By default the repo will be cloned into the root of your Workspace.

## Parameters
|name|description|default value|required|
|---|---|---|---|
|url|Repository URL to clone from.||true|
|revision|Revision to checkout. (branch, tag, sha, ref, etc...)|""|false|
|refspec|Refspec to fetch before checking out revision.|""|false|
|submodules|Initialize and fetch git submodules.|true|false|
|depth|Perform a shallow clone, fetching only the most recent N commits.|1|false|
|shortCommitLength|Length of short commit SHA|7|false|
|sslVerify|Set the `http.sslVerify` global git config. Setting this to `false` is not advised unless you are sure that you trust your git remote.|true|false|
|subdirectory|Subdirectory inside the `output` Workspace to clone the repo into.|source|false|
|sparseCheckoutDirectories|Define the directory patterns to match or exclude when performing a sparse checkout.|""|false|
|deleteExisting|Clean out the contents of the destination directory if it already exists before cloning.|true|false|
|httpProxy|HTTP proxy server for non-SSL requests.|""|false|
|httpsProxy|HTTPS proxy server for SSL requests.|""|false|
|noProxy|Opt out of proxying HTTP/HTTPS requests.|""|false|
|verbose|Log the commands that are executed during `git-clone`'s operation.|false|false|
|gitInitImage|Deprecated. Has no effect. Will be removed in the future.|""|false|
|userHome|Absolute path to the user's home directory. Set this explicitly if you are running the image as a non-root user. |/tekton/home|false|
|enableSymlinkCheck|Check symlinks in the repo. If they're pointing outside of the repo, the build will fail. |true|false|
|fetchTags|Fetch all tags for the repo.|false|false|
|caTrustConfigMapName|The name of the ConfigMap to read CA bundle data from.|trusted-ca|false|
|caTrustConfigMapKey|The name of the key in the ConfigMap that contains the CA bundle data.|ca-bundle.crt|false|
|mergeTargetBranch|Whether to merge the target branch into the revision after checkout.|false|false|
|targetBranch|The target branch to merge into the revision (if mergeTargetBranch is true).|"main"|false|

## Results
|name|description|
|---|---|
|commit|The precise commit SHA that was fetched by this Task.|
|short-commit|The commit SHA that was fetched by this Task limited to params.shortCommitLength number of characters|
|url|The precise URL that was fetched by this Task.|
|merged_sha|The SHA of the commit after merging the target branch (if mergeTargetBranch is true) |
|commit-timestamp|The commit timestamp of the checkout|
|CHAINS-GIT_URL|The precise URL that was fetched by this Task. This result uses Chains type hinting to include in the provenance.|
|CHAINS-GIT_COMMIT|The precise commit SHA that was fetched by this Task. This result uses Chains type hinting to include in the provenance.|

## Workspaces
|name|description|optional|
|---|---|---|
|output|The git repo will be cloned onto the volume backing this Workspace.|false|
|ssh-directory|A .ssh directory with private key, known_hosts, config, etc. Copied to the user's home before git commands are executed. Used to authenticate with the git remote when performing the clone. Binding a Secret to this Workspace is strongly recommended over other volume types. |true|
|basic-auth|A Workspace containing a .gitconfig and .git-credentials file or username and password. These will be copied to the user's home before any git commands are run. Any other files in this Workspace are ignored. It is strongly recommended to use ssh-directory over basic-auth whenever possible and to bind a Secret to this Workspace over other volume types. |true|
