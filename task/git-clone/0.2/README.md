# git-clone task

The git-clone Task will clone a repo from the provided url into the output Workspace. By default the repo will be cloned into the root of your Workspace.

## Parameters
|name|description|default value|required|
|---|---|---|---|
|url|Repository URL to clone from.||true|
|revision|Revision to checkout. (branch, tag, sha, ref, etc...)|""|false|
|refspec|Refspec to fetch before checking out revision.|""|false|
|submodules|Initialize and fetch git submodules.|true|false|
|submodulePaths|Comma-separated list of specific submodule paths to initialize and fetch. Only submodules in the specified directories and their subdirectories will be fetched. Empty string fetches all submodules. Parameter "submodules" must be set to "true" to make this parameter applicable.|""|false|
|depth|Perform a shallow clone, fetching only the most recent N commits.|1|false|
|shortCommitLength|Minimum length of the short commit SHA. Git may return a longer prefix if needed for uniqueness.|7|false|
|sslVerify|Set the `http.sslVerify` global git config. Setting this to `false` is not advised unless you are sure that you trust your git remote.|true|false|
|subdirectory|Subdirectory inside the `output` Workspace to clone the repo into.|source|false|
|sparseCheckoutDirectories|Define the directory patterns to match or exclude when performing a sparse checkout.|""|false|
|deleteExisting|Clean out the contents of the destination directory if it already exists before cloning.|true|false|
|httpProxy|HTTP proxy server for non-SSL requests.|""|false|
|httpsProxy|HTTPS proxy server for SSL requests.|""|false|
|logLevel|Log level for the git-clone command.|info|false|
|noProxy|Opt out of proxying HTTP/HTTPS requests.|""|false|
|enableSymlinkCheck|Check symlinks in the repo. If they're pointing outside of the repo, the build will fail. |true|false|
|symlinkCheckIgnorePattern|CSV list of path patterns to exclude from the symlink check. Symlinks whose paths match are not checked. Patterns are relative to the checkout directory and must not start with '/'. Use '*' and '?' as wildcards ('*' matches across '/'). Quote patterns containing commas using CSV double quotes. |""|false|
|fetchTags|Fetch all tags for the repo.|false|false|
|caTrustConfigMapName|The name of the ConfigMap to read CA bundle data from.|trusted-ca|false|
|caTrustConfigMapKey|The name of the key in the ConfigMap that contains the CA bundle data.|ca-bundle.crt|false|
|mergeTargetBranch|Set to "true" to merge the targetBranch into the checked-out revision.|false|false|
|targetBranch|The target branch to merge into the revision (if mergeTargetBranch is true).|main|false|
|mergeSourceRepoUrl|URL of the repository to fetch the target branch from when mergeTargetBranch is true. If empty, uses the same repository (origin). This allows merging a branch from a different repository. |""|false|
|mergeSourceDepth|Perform a shallow fetch of the target branch, fetching only the most recent N commits. If empty, fetches the full history of the target branch. |""|false|

## Results
|name|description|
|---|---|
|commit|The precise commit SHA that was fetched by this Task.|
|short-commit|Abbreviated commit SHA for the checkout. At least params.shortCommitLength characters; longer if Git requires more for uniqueness.|
|url|The precise URL that was fetched by this Task.|
|commit-timestamp|The commit timestamp of the checkout|
|CHAINS-GIT_URL|The precise URL that was fetched by this Task. This result uses Chains type hinting to include in the provenance.|
|CHAINS-GIT_COMMIT|The precise commit SHA that was fetched by this Task. This result uses Chains type hinting to include in the provenance.|
|merged_sha|The SHA of the commit after merging the target branch (if the param mergeTargetBranch is true).|

## Workspaces
|name|description|optional|
|---|---|---|
|output|The git repo will be cloned onto the volume backing this Workspace.|false|
|ssh-directory|A .ssh directory with private key, known_hosts, config, etc. Copied to the user's home before git commands are executed. Used to authenticate with the git remote when performing the clone. Binding a Secret to this Workspace is strongly recommended over other volume types. |true|
|basic-auth|A Workspace containing a .gitconfig and .git-credentials file or username and password. These will be copied to the user's home before any git commands are run. Any other files in this Workspace are ignored. It is strongly recommended to use ssh-directory over basic-auth whenever possible and to bind a Secret to this Workspace over other volume types. |true|

## Additional info
