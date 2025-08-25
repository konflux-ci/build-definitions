# buildah-rhtap task

Buildah task builds source code into a container image and pushes the image into container registry using buildah tool.
In addition it generates a SBOM file, injects the SBOM file into final container image and pushes the SBOM file as separate image using cosign tool.

## Parameters
|name|description|default value|required|
|---|---|---|---|
|IMAGE|Reference of the image buildah will produce.||true|
|DOCKERFILE|Path to the Dockerfile to build.|./Dockerfile|false|
|CONTEXT|Path to the directory to use as context.|.|false|
|TLSVERIFY|Verify the TLS on the registry endpoint (for push/pull to a non-TLS registry)|true|false|
|BUILD_ARGS|Array of --build-arg values ("arg=value" strings)|[]|false|
|BUILD_ARGS_FILE|Path to a file with build arguments, see https://www.mankier.com/1/buildah-build#--build-arg-file|""|false|
|STORAGE_DRIVER|Storage driver to configure for buildah|vfs|false|

## Results
|name|description|
|---|---|
|IMAGE_DIGEST|Digest of the image just built|
|IMAGE_URL|Image repository and tag where the built image was pushed|
|BASE_IMAGES_DIGESTS|Digests of the base images used for build|
|SBOM_BLOB_URL|Link to the SBOM layer pushed to the registry as part of an OCI artifact.|

## Workspaces
|name|description|optional|
|---|---|---|
|source|Workspace containing the source code to build.|false|

## Additional info
