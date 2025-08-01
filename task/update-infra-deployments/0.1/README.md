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

## Workspaces
|name|description|optional|
|---|---|---|
|artifacts|Workspace containing arbitrary artifacts used during the task run.|true|
