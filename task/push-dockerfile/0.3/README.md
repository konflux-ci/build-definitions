# push-dockerfile task

Discover Dockerfile from source code and push it to registry as an OCI artifact.

## Parameters
|name|description|default value|required|
|---|---|---|---|
|IMAGE|The built binary image. The Dockerfile is pushed to the same image repository alongside.||true|
|IMAGE_DIGEST|The built binary image digest, which is used to construct the tag of Dockerfile image.||true|
|DOCKERFILE|Path to the Dockerfile.|./Dockerfile|false|
|CONTEXT|Path to the directory to use as context.|.|false|
|TAG_SUFFIX|Suffix of the Dockerfile image tag.|.dockerfile|false|
|ARTIFACT_TYPE|Artifact type of the Dockerfile image.|application/vnd.konflux.dockerfile|false|
|CA_TRUST_CONFIG_MAP_NAME|The name of the ConfigMap to read CA bundle data from.|trusted-ca|false|
|CA_TRUST_CONFIG_MAP_KEY|The name of the key in the ConfigMap that contains the CA bundle data.|ca-bundle.crt|false|

## Results
|name|description|
|---|---|
|IMAGE_REF|Digest-pinned image reference to the Dockerfile image.|

## Workspaces
|name|description|optional|
|---|---|---|
|workspace|Workspace containing the source code from where the Dockerfile is discovered.|false|

## Additional info
