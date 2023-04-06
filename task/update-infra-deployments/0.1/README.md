# update-infra-deployments task

Clones redhat-appstudio/infra-deployments repository, runs script in 'SCRIPT' parameter, generates pull-request for redhat-appstudio/infra-deployments repository.


## Parameters
|name|description|default value|required|
|---|---|---|---|
|SCRIPT|Bash script for changing the infra-deployments||true|
|ORIGIN_REPO|URL of github repository which was built by the Pipeline||true|
|REVISION|Git reference which was built by the Pipeline||true|
|TARGET_GH_REPO|GitHub repository of the infra-deployments code|redhat-appstudio/infra-deployments|false|
|GIT_IMAGE|Image reference containing the git command|registry.redhat.io/openshift-pipelines/pipelines-git-init-rhel8:v1.8.2-8@sha256:a538c423e7a11aae6ae582a411fdb090936458075f99af4ce5add038bb6983e8|false|
|SCRIPT_IMAGE|Image reference for SCRIPT execution|quay.io/mkovarik/ose-cli-git:4.11|false|
|shared-secret|secret in the namespace which contains private key for the GitHub App|infra-deployments-pr-creator|false|
|GITHUB_APP_ID|ID of Github app used for updating PR|305606|false|
|GITHUB_APP_INSTALLATION_ID|Installation ID of Github app in the organization|35269675|false|

