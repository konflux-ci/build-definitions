# build-image-manifest task

This takes existing images and stiches them together into a multi platform image.

## Parameters
|name|description|default value|required|
|---|---|---|---|
|IMAGE|Reference of the image buildah will produce.||true|
|TLSVERIFY|Verify the TLS on the registry endpoint (for push/pull to a non-TLS registry)|true|false|
|COMMIT_SHA|The image is built from this commit.|""|false|
|IMAGES|List of images that are to be merged into the multi platform image||true|
|IMAGE_EXPIRES_AFTER|Delete image tag after specified time. Empty means to keep the image tag. Time values could be something like 1h, 2d, 3w for hours, days, and weeks, respectively.|""|false|
|STORAGE_DRIVER|Storage driver to configure for buildah|vfs|false|

## Results
|name|description|
|---|---|
|IMAGE_DIGEST|Digest of the image just built|
|IMAGE_URL|Image repository and tag where the built image was pushed|
|IMAGES|List of all referenced image manifests|

