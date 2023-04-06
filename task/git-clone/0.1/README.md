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
|sslVerify|Set the `http.sslVerify` global git config. Setting this to `false` is not advised unless you are sure that you trust your git remote.|true|false|
|subdirectory|Subdirectory inside the `output` Workspace to clone the repo into.|""|false|
|sparseCheckoutDirectories|Define the directory patterns to match or exclude when performing a sparse checkout.|""|false|
|deleteExisting|Clean out the contents of the destination directory if it already exists before cloning.|true|false|
|httpProxy|HTTP proxy server for non-SSL requests.|""|false|
|httpsProxy|HTTPS proxy server for SSL requests.|""|false|
|noProxy|Opt out of proxying HTTP/HTTPS requests.|""|false|
|verbose|Log the commands that are executed during `git-clone`'s operation.|true|false|
|gitInitImage|The image providing the git-init binary that this Task runs.|registry.redhat.io/openshift-pipelines/pipelines-git-init-rhel8:v1.8.2-8@sha256:a538c423e7a11aae6ae582a411fdb090936458075f99af4ce5add038bb6983e8|false|
|userHome|Absolute path to the user's home directory. Set this explicitly if you are running the image as a non-root user or have overridden the gitInitImage param with an image containing custom user configuration. |/tekton/home|false|

## Results
|name|description|
|---|---|
|commit|The precise commit SHA that was fetched by this Task.|
|url|The precise URL that was fetched by this Task.|

## Workspaces
|name|description|optional|
|---|---|---|
|output|The git repo will be cloned onto the volume backing this Workspace.|false|
|ssh-directory|A .ssh directory with private key, known_hosts, config, etc. Copied to the user's home before git commands are executed. Used to authenticate with the git remote when performing the clone. Binding a Secret to this Workspace is strongly recommended over other volume types. |true|
|basic-auth|A Workspace containing a .gitconfig and .git-credentials file. These will be copied to the user's home before any git commands are run. Any other files in this Workspace are ignored. It is strongly recommended to use ssh-directory over basic-auth whenever possible and to bind a Secret to this Workspace over other volume types. |true|
