# rpm-ostree task

RPM Ostree

## Parameters
|name|description|default value|required|
|---|---|---|---|
|IMAGE|Reference of the image rpm-ostree will produce.||true|
|BUILDER_IMAGE|The location of the rpm-ostree builder image.|quay.io/redhat-user-workloads/project-sagano-tenant/ostree-builder/ostree-builder-fedora-38:d124414a81d17f31b1d734236f55272a241703d7|false|
|CONTEXT|Path to the directory to use as context.|.|false|
|IMAGE_FILE|The file to use to build the image||true|
|TLSVERIFY|Verify the TLS on the registry endpoint (for push/pull to a non-TLS registry)|true|false|
|IMAGE_EXPIRES_AFTER|Delete image tag after specified time. Empty means to keep the image tag. Time values could be something like 1h, 2d, 3w for hours, days, and weeks, respectively.|""|false|
|COMMIT_SHA|The image is built from this commit.|""|false|
|PLATFORM|The platform to build on||true|
|CONFIG_FILE|The relative path of the file used to configure the rpm-ostree tool found in source control. See https://github.com/coreos/rpm-ostree/blob/main/docs/container.md#adding-container-image-configuration|""|false|
|HERMETIC|Determines if build will be executed without network access.|false|false|

## Results
|name|description|
|---|---|
|IMAGE_DIGEST|Digest of the image just built|
|IMAGE_URL|Image repository and tag where the built image was pushed|
|IMAGE_REF|Image reference of the built image|
|BASE_IMAGES_DIGESTS|Digests of the base images used for build|
|SBOM_BLOB_URL|Reference, including digest to the SBOM blob|

## Workspaces
|name|description|optional|
|---|---|---|
|source|Workspace containing the source code to build.|false|
