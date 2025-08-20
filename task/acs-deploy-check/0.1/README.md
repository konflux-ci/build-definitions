# acs-deploy-check task

Policy check a deployment with StackRox/RHACS This tasks allows you to check a deployment against build-time policies and apply enforcement to fail builds. It's a companion to the stackrox-image-scan task, which returns full vulnerability scan results for an image.

## Parameters
|name|description|default value|required|
|---|---|---|---|
|rox-secret-name|Secret containing the StackRox server endpoint and API token with CI permissions under rox-api-endpoint and rox-api-token keys. For example: rox-api-endpoint: rox.stackrox.io:443 ; rox-api-token: eyJhbGciOiJS... ||true|
|gitops-repo-url|URL of gitops repository to check.||true|
|verbose||true|false|
|insecure-skip-tls-verify|When set to `"true"`, skip verifying the TLS certs of the Central endpoint. Defaults to `"false"`. |false|false|
|gitops-auth-secret-name|Secret of basic-auth type containing credentials to clone the gitops repository. |gitops-auth-secret|false|

## Workspaces
|name|description|optional|
|---|---|---|
|gitops-auth||true|

## Additional info
