# update-infra-deployments task

Clones redhat-appstudio/infra-deployments repository, runs script in 'SCRIPT' parameter, generates pull-request for redhat-appstudio/infra-deployments repository.


## Parameters
|name|description|default value|required|
|---|---|---|---|
|SCRIPT|Bash script for changing the infra-deployments||true|
|ORIGIN_REPO|URL of github repository which was built by the Pipeline||true|
|REVISION|Git reference which was built by the Pipeline||true|
|TARGET_GH_REPO|GitHub repository of the infra-deployments code|redhat-appstudio/infra-deployments|false|
|GIT_IMAGE|Deprecated. Has no effect. Will be removed in the future.|""|false|
|SCRIPT_IMAGE|Deprecated. Has no effect. Will be removed in the future.|""|false|
|shared-secret|secret in the namespace which contains private key for the GitHub App|infra-deployments-pr-creator|false|
|GITHUB_APP_ID|ID of Github app used for updating PR|305606|false|
|GITHUB_APP_INSTALLATION_ID|Installation ID of Github app in the organization|35269675|false|
|ALLOW_NON_HEAD_COMMIT_UPDATE|When set to "false", the task will fail unless the REVISION param is the latest (HEAD) commit on the "main" branch of the ORIGIN_REPO. This prevents creating or updating a PR that would run the SCRIPT on a non-head commit. (e.g., if the SCRIPT updates references, this check prevents them from being updated to an outdated version)  Downsides of this approach are:   1. description of a PR would be missing a link on failure   2. can be problematic for repos where the update task (or the whole push pipeline) doesn't run on every commit.      e.g., Merge one PR, then quickly merge one that doesn't run the update - now the update task is blocked until we merge something that does run the update task |false|false|

## Workspaces
|name|description|optional|
|---|---|---|
|artifacts|Workspace containing arbitrary artifacts used during the task run.|true|
