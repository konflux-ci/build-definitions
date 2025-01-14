# build-paketo-builder-oci-ta task

The `build-paketo-builder-oci-ta` task builds a builder image (e.g. https://github.com/paketo-community/builder-ubi-base) for paketo using as input the [builder.toml](https://buildpacks.io/docs/reference/config/builder-config/) file. The image is build using the pack tool packaged part of the [paketo-container](https://github.com/konflux-ci/paketo-container/) image.
The task also produces the SBOM which is signed and added to the image.

## Parameters

| name                 | description                                                                         | default value | required |
|----------------------|-------------------------------------------------------------------------------------|---------------|----------|
| BUILD_ARGS           | Array of --build-arg values ("arg=value" strings)                                   | []            | false    |
| CACHI2_ARTIFACT      | The Trusted Artifact URI pointing to the artifact with the prefetched dependencies. | ""            | false    |
| CONTEXT              | Path to the directory to use as context.                                            | .             | false    |
| HERMETIC             | Determines if build will be executed without network access.                        | false         | false    |
| IMAGE                | Reference of the image buildah will produce.                                        |               | true     |
| PLATFORM             | The platform to build on                                                            |               | true     |
| SOURCE_ARTIFACT      | The Trusted Artifact URI pointing to the artifact with the application source code. |               | true     |
| SOURCE_CODE_DIR      | The subpath of the application source code.                                         | "."           | true     |
| STORAGE_DRIVER       | Storage driver to configure for buildah                                             | vfs           | false    |
| TLSVERIFY            | Verify the TLS on the registry endpoint (for push/pull to a non-TLS registry)       | true          | false    |
| caTrustConfigMapKey  | The name of the key in the ConfigMap that contains the CA bundle data.              | ca-bundle.crt | false    |
| caTrustConfigMapName | The name of the ConfigMap to read CA bundle data from.                              | trusted-ca    | false    |

## Results
|name|description|
|---|---|
|BASE_IMAGES_DIGESTS|Digests of the base images used for build|
|IMAGE_DIGEST|Digest of the image just built|
|IMAGE_REF|Image reference of the built image|
|IMAGE_URL|Image repository and tag where the built image was pushed|
|SBOM_BLOB_URL|Reference of SBOM blob digest to enable digest-based verification from provenance|
