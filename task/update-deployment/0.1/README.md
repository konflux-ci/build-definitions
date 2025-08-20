# update-deployment task

Task to update deployment with newly built image in gitops repository.

## Parameters
|name|description|default value|required|
|---|---|---|---|
|gitops-repo-url|URL of gitops repository to update with the newly built image.||true|
|image|Reference of the newly built image to use.||true|
|gitops-auth-secret-name|Secret of basic-auth type containing credentials to commit into gitops repository. |gitops-auth-secret|false|

## Workspaces
|name|description|optional|
|---|---|---|
|gitops-auth||true|

## Additional info
