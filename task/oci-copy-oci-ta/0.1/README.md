# oci-copy-oci-ta task

Given an `oci-copy.yaml` file in the user's source directory, the `oci-copy` task will copy content from arbitrary urls into the OCI registry.

It generates a limited SBOM and pushes that into the OCI registry alongside the image.

It is not to be considered safe for general use as it cannot provide a high degree of provenance for artficats and reports them only as "general" type artifacts in the purl spec it reports in the SBOM. Use only in limited situations.

## Parameters
|name|description|default value|required|
|---|---|---|---|
|IMAGE|Reference of the image buildah will produce.||true|
|SOURCE_ARTIFACT|The trusted artifact URI containing the application source code.||true|
|OCI_COPY_FILE|Path to the oci copy file.|./oci-copy.yaml|false|

## Results
|name|description|
|---|---|
|IMAGE_DIGEST|Digest of the image just built|
|IMAGE_URL|Image repository where the built image was pushed|

