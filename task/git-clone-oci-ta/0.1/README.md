# git-clone-oci-ta task

The git-clone-oci-ta Task will clone a repo from the provided url and store it as a trusted artifact in the provided OCI repository.

## Parameters
|name|description|default value|required|
|---|---|---|---|
|caTrustConfigMapKey|The name of the key in the ConfigMap that contains the CA bundle data.|ca-bundle.crt|false|
|caTrustConfigMapName|The name of the ConfigMap to read CA bundle data from.|trusted-ca|false|
|depth|Perform a shallow clone, fetching only the most recent N commits.|1|false|
|enableSymlinkCheck|Check symlinks in the repo. If they're pointing outside of the repo, the build will fail. |true|false|
|fetchTags|Fetch all tags for the repo.|false|false|
|httpProxy|HTTP proxy server for non-SSL requests.|""|false|
|httpsProxy|HTTPS proxy server for SSL requests.|""|false|
|mergeTargetBranch|Set to "true" to merge the targetBranch into the checked-out revision.|false|false|
|noProxy|Opt out of proxying HTTP/HTTPS requests.|""|false|
|ociArtifactExpiresAfter|Expiration date for the trusted artifacts created in the OCI repository. An empty string means the artifacts do not expire.|""|false|
|ociStorage|The OCI repository where the Trusted Artifacts are stored.||true|
|refspec|Refspec to fetch before checking out revision.|""|false|
|revision|Revision to checkout. (branch, tag, sha, ref, etc...)|""|false|
|shortCommitLength|Length of short commit SHA|7|false|
|sparseCheckoutDirectories|Define the directory patterns to match or exclude when performing a sparse checkout.|""|false|
|sslVerify|Set the `http.sslVerify` global git config. Setting this to `false` is not advised unless you are sure that you trust your git remote.|true|false|
|submodules|Initialize and fetch git submodules.|true|false|
|targetBranch|The target branch to merge into the revision (if mergeTargetBranch is true).|main|false|
|url|Repository URL to clone from.||true|
|userHome|Absolute path to the user's home directory. Set this explicitly if you are running the image as a non-root user. |/tekton/home|false|
|verbose|Log the commands that are executed during `git-clone`'s operation.|false|false|

## Results
|name|description|
|---|---|
|CHAINS-GIT_COMMIT|The precise commit SHA that was fetched by this Task. This result uses Chains type hinting to include in the provenance.|
|CHAINS-GIT_URL|The precise URL that was fetched by this Task. This result uses Chains type hinting to include in the provenance.|
|SOURCE_ARTIFACT|The Trusted Artifact URI pointing to the artifact with the application source code.|
|commit|The precise commit SHA that was fetched by this Task.|
|commit-timestamp|The commit timestamp of the checkout|
|merged_sha|The SHA of the commit after merging the target branch (if the param mergeTargetBranch is true).|
|short-commit|The commit SHA that was fetched by this Task limited to params.shortCommitLength number of characters|
|url|The precise URL that was fetched by this Task.|

## Workspaces
|name|description|optional|
|---|---|---|
|basic-auth|A Workspace containing a .gitconfig and .git-credentials file or username and password. These will be copied to the user's home before any git commands are run. Any other files in this Workspace are ignored. It is strongly recommended to use ssh-directory over basic-auth whenever possible and to bind a Secret to this Workspace over other volume types. |true|
|ssh-directory|A .ssh directory with private key, known_hosts, config, etc. Copied to the user's home before git commands are executed. Used to authenticate with the git remote when performing the clone. Binding a Secret to this Workspace is strongly recommended over other volume types. |true|
