# buildah-remote task

This task is programmatically generated from the buildah task to keep it in sync, it should not be manually modified.

Buildah task builds source code into a container image and pushes the image into container registry using buildah tool, however while the standard buildah task is run directly on the cluster, this task is run on a remote host. This must be used in combination with the [Multi Arch Controller](https://github.com/redhat-appstudio/multi-arch-controller) which provides the credentials and host name to use to perform the build.

This task has an additional `PLATFORM` param that is used by the Multi Arch Controller to decide which host should perform the build.



## Parameters
| name                | description                                                                                                                                                        |default value|required|
|---------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------|---|---|
| PLATFORM            | The target platform.                                                                                                                                               ||true|
| IMAGE               | Reference of the image buildah will produce.                                                                                                                       ||true|
| DOCKERFILE          | Path to the Dockerfile to build.                                                                                                                                   |./Dockerfile|false|
| CONTEXT             | Path to the directory to use as context.                                                                                                                           |.|false|
| TLSVERIFY           | Verify the TLS on the registry endpoint (for push/pull to a non-TLS registry)                                                                                      |true|false|
| HERMETIC            | Determines if build will be executed without network access.                                                                                                       |false|false|
| PREFETCH_INPUT      | In case it is not empty, the prefetched content should be made available to the build.                                                                             |""|false|
| IMAGE_EXPIRES_AFTER | Delete image tag after specified time. Empty means to keep the image tag. Time values could be something like 1h, 2d, 3w for hours, days, and weeks, respectively. |""|false|

## Results
|name|description|
|---|---|
|IMAGE_DIGEST|Digest of the image just built|
|IMAGE_URL|Image repository where the built image was pushed|
|BASE_IMAGES_DIGESTS|Digests of the base images used for build|
|SBOM_JAVA_COMPONENTS_COUNT|The counting of Java components by publisher in JSON format|
|JAVA_COMMUNITY_DEPENDENCIES|The Java dependencies that came from community sources such as Maven central.|

## Workspaces
|name|description|optional|
|---|---|---|
|source|Workspace containing the source code to build.|false|
