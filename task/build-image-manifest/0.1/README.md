# build-image-manifest task

This task generates an image manifest from a collection of existing single platform images to create a multi-platform image.

## Parameters
| name                | description                                                                                                                                                        |default value|required|
|---------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------|---|---|
| IMAGE               | Reference of the image buildah will produce.                                                                                                                       ||true|
| BUILDER_IMAGE       | The location of the buildah builder image.                                                                                                                         |registry.access.redhat.com/ubi9/buildah:9.0.0-19@sha256:c8b1d312815452964885680fc5bc8d99b3bfe9b6961228c71a09c72ca8e915eb|false|
| TLSVERIFY           | Verify the TLS on the registry endpoint (for push/pull to a non-TLS registry)                                                                                      |true|false|
| COMMIT_SHA          | The git commit sha that was used to produce the images                                                                                                             |""|false|
| IMAGES              | List of images that should be merged into a multi arch image                                                                                                       |false|false|
| IMAGE_EXPIRES_AFTER | Delete image tag after specified time. Empty means to keep the image tag. Time values could be something like 1h, 2d, 3w for hours, days, and weeks, respectively. |""|false|

## Results
|name|description|
|---|---|
|IMAGE_DIGEST|Digest of the image just built|
|IMAGE_URL|Image repository where the built image was pushed|

