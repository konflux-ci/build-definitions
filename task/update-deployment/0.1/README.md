# update-deployment task

Task to update deployment with newly built image in gitops repository.

## Parameters
|name|description|default value|required|
|---|---|---|---|
|gitops-repo-url|URL of gitops repository to update with the newly built image||true|
|image|reference of the newly built image to use||true|

## Workspaces
|name|description|optional|
|---|---|---|
|basic-auth||true|
