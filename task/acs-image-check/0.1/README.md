# acs-image-check task

Policy check an image with StackRox/RHACS This tasks allows you to check an image against build-time policies and apply enforcement to fail builds. It's a companion to the stackrox-image-scan task, which returns full vulnerability scan results for an image.

## Parameters
|name|description|default value|required|
|---|---|---|---|
|rox-secret-name|Secret containing the StackRox server endpoint and API token with CI permissions under rox-api-endpoint and rox-api-token keys. For example: rox-api-endpoint: rox.stackrox.io:443 ; rox-api-token: eyJhbGciOiJS... ||true|
|image|Full name of image to scan (example -- gcr.io/rox/sample:5.0-rc1) ||true|
|insecure-skip-tls-verify|When set to `"true"`, skip verifying the TLS certs of the Central endpoint.  Defaults to `"false"`. |false|false|
|image-digest|Digest of the image ||true|


## Additional info
