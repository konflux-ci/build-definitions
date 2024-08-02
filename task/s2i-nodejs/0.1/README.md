# s2i-nodejs task

s2i-nodejs task builds source code into a container image and pushes the image into container registry using S2I and buildah tool.
In addition it generates a SBOM file, injects the SBOM file into final container image and pushes the SBOM file as separate image using cosign tool.


## Parameters
|name|description|default value|required|
|---|---|---|---|
|BASE_IMAGE|NodeJS builder image|registry.access.redhat.com/ubi9/nodejs-16:1-75.1669634583@sha256:c17111ec54c7f57f22d03f2abba206b0bdc54dcdfb02d6a8278ce088231eced1|false|
|PATH_CONTEXT|The location of the path to run s2i from.|.|false|
|TLSVERIFY|Verify the TLS on the registry endpoint (for push/pull to a non-TLS registry)|true|false|
|IMAGE|Location of the repo where image has to be pushed||true|
|BUILDER_IMAGE|Deprecated. Has no effect. Will be removed in the future.|""|false|
|DOCKER_AUTH|unused, should be removed in next task version|""|false|
|IMAGE_EXPIRES_AFTER|Delete image tag after specified time. Empty means to keep the image tag. Time values could be something like 1h, 2d, 3w for hours, days, and weeks, respectively.|""|false|
|MAVEN_MIRROR_URL|The base URL of a mirror used for retrieving artifacts|""|false|
|COMMIT_SHA|The image is built from this commit.|""|false|

## Results
|name|description|
|---|---|
|IMAGE_DIGEST|Digest of the image just built|
|IMAGE_URL|Image repository and tag where the built image was pushed|
|IMAGE_REF|Image reference of the built image|
|BASE_IMAGES_DIGESTS|Digests of the base images used for build|

## Workspaces
|name|description|optional|
|---|---|---|
|source|Workspace containing the source code to build.|false|
