# build-image-index task

This takes existing Image Manifests and combines them in an Image Index.

## Parameters
|name|description|default value|required|
|---|---|---|---|
|IMAGE|The target image and tag where the image will be pushed to.||true|
|TLSVERIFY|Verify the TLS on the registry endpoint (for push/pull to a non-TLS registry)|true|false|
|COMMIT_SHA|The commit the image is built from.|""|false|
|IMAGES|List of Image Manifests to be referenced by the Image Index||true|
|IMAGE_EXPIRES_AFTER|Delete image tag after specified time resulting in garbage collection of the digest. Empty means to keep the image tag. Time values could be something like 1h, 2d, 3w for hours, days, and weeks, respectively.|""|false|
|ALWAYS_BUILD_INDEX|Build an image index even if IMAGES is of length 1. Default true. If the image index generation is skipped, the task will forward values for params.IMAGES[0] to results.IMAGE_*. In order to properly set all results, use the repository:tag@sha256:digest format for the IMAGES parameter.|true|false|
|STORAGE_DRIVER|Storage driver to configure for buildah|vfs|false|

## Results
|name|description|
|---|---|
|IMAGE_DIGEST|Digest of the image just built|
|IMAGE_URL|Image repository and tag where the built image was pushed|
|IMAGES|List of all referenced image manifests|
|IMAGE_REF|Image reference of the built image containing both the repository and the digest|

