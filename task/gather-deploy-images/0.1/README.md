# gather-deploy-images task

Extract images from deployment YAML to pass to EC for validation

## Results
|name|description|
|---|---|
|IMAGES_TO_VERIFY|The images to be verified, in a format compatible with https://github.com/redhat-appstudio/build-definitions/tree/main/task/verify-enterprise-contract/0.1|

## Workspaces
|name|description|optional|
|---|---|---|
|source|Should contain a cloned gitops repo at the ./source subpath|false|
