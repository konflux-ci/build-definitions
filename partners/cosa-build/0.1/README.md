# cosa-build task

Build a container with the CoreOS assembler

## Parameters
|name|description|default value|required|
|---|---|---|---|
|BUILDER_IMAGE|The location of the CoreOS assembler builder image.|quay.io/coreos-assembler/coreos-assembler:latest|false|
|CACHI2_ARTIFACT|The Trusted Artifact URI pointing to the artifact with the prefetched dependencies.|""|false|
|HERMETIC|Determines if build will be executed without network access.|false|false|
|IMAGE|Reference of the image cosa-build will produce.||true|
|IMAGE_APPEND_PLATFORM|Whether to append a sanitized platform architecture on the IMAGE tag|false|false|
|NO_KVM|Determines if build will be executed without KVM at the cost of performance.|true|false|
|PLATFORM|The platform to build on||true|
|SBOM_TYPE|Select the SBOM format to generate. Valid values: spdx, cyclonedx. Note: the SBOM from the prefetch task - if there is one - must be in the same format.|spdx|false|
|SKIP_SBOM_GENERATION|Skip SBOM-related operations. This will likely cause EC policies to fail if enabled|false|false|
|SOURCE_ARTIFACT|The Trusted Artifact URI pointing to the artifact with the application source code.||true|
|TLSVERIFY|Verify the TLS on the registry endpoint (for push/pull to a non-TLS registry)|true|false|
|VARIANT|Select variant you want to build.|""|false|

## Results
|name|description|
|---|---|
|IMAGE_DIGEST|Digest of the image just built|
|IMAGE_REF|Image reference of the built image|
|IMAGE_URL|Image repository and tag where the built image was pushed|
|SBOM_BLOB_URL|Reference, including digest to the SBOM blob|

