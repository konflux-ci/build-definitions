# build-paketo-builder-oci-ta task

build-paketo-builder-oci-ta task builds an image of a paketo builder project using as input the builder.toml file.
The task also produces the SBOM which is signed and added to the image.

## Parameters
|name|description|default value|required|
|---|---|---|---|
|BUILD_ARGS|the arguments to be passed to the pack command to build the image|[]|false|
|CACHI2_ARTIFACT|The Trusted Artifact URI pointing to the artifact with the prefetched dependencies.|""|false|
|CONTEXT|Path to the directory to use as context.|.|false|
|HERMETIC|Determines if build will be executed without network access.|false|false|
|IMAGE|Reference of the image that pack will produce.||true|
|PLATFORM|The VM OS type to be used to run the podman container doing the build|linux-mlarge/amd64|false|
|SOURCE_ARTIFACT|The Trusted Artifact URI pointing to the artifact with the application source code.||true|
|SOURCE_CODE_DIR|The directory containing the code source|.|false|
|STORAGE_DRIVER|Storage driver to configure for buildah|vfs|false|
|TLSVERIFY|Verify the TLS on the registry endpoint (for push/pull to a non-TLS registry)|true|false|
|SBOM_TYPE|Select the SBOM format to generate. Valid values: spdx, cyclonedx. Note: the SBOM from the prefetch task - if there is one - must be in the same format.|spdx|false|
|caTrustConfigMapKey|The name of the key in the ConfigMap that contains the CA bundle data.|ca-bundle.crt|false|
|caTrustConfigMapName|The name of the ConfigMap to read CA bundle data from.|trusted-ca|false|

## Results
|name|description|
|---|---|
|IMAGE_URL|Image repository and tag where the built image was pushed|
|IMAGE_DIGEST|Digest of the image just built|
|IMAGE_REF|Image reference of the built image|
|BASE_IMAGES_DIGESTS|Digests of the base images used for build|
|SBOM_BLOB_URL|SBOM Image URL|


## Additional info
