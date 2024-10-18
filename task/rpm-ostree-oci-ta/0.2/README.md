# rpm-ostree-oci-ta task

RPM Ostree (Trusted Artifacts variant).

## Parameters
|name|description|default value|required|
|---|---|---|---|
|BUILDER_IMAGE|The location of the rpm-ostree builder image.|quay.io/redhat-user-workloads/project-sagano-tenant/ostree-builder/ostree-builder-fedora-38:d124414a81d17f31b1d734236f55272a241703d7|false|
|CACHI2_ARTIFACT|The Trusted Artifact URI pointing to the artifact with the prefetched dependencies.|""|false|
|COMMIT_SHA|The image is built from this commit.|""|false|
|CONFIG_FILE|The relative path of the file used to configure the rpm-ostree tool found in source control. See https://github.com/coreos/rpm-ostree/blob/main/docs/container.md#adding-container-image-configuration|""|false|
|CONTEXT|Path to the directory to use as context.|.|false|
|HERMETIC|Determines if build will be executed without network access.|false|false|
|IMAGE|Reference of the image rpm-ostree will produce.||true|
|IMAGE_EXPIRES_AFTER|Delete image tag after specified time. Empty means to keep the image tag. Time values could be something like 1h, 2d, 3w for hours, days, and weeks, respectively.|""|false|
|IMAGE_FILE|The file to use to build the image||true|
|PLATFORM|The platform to build on||true|
|SOURCE_ARTIFACT|The Trusted Artifact URI pointing to the artifact with the application source code.||true|
|TLSVERIFY|Verify the TLS on the registry endpoint (for push/pull to a non-TLS registry)|true|false|

## Results
|name|description|
|---|---|
|IMAGE_DIGEST|Digest of the image just built|
|IMAGE_REF|Image reference of the built image|
|IMAGE_URL|Image repository and tag where the built image was pushed|
|SBOM_BLOB_URL|Reference, including digest to the SBOM blob|

