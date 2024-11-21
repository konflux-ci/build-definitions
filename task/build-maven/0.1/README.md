# build maven task

Build maven task builds source dependency files and checksums into a zip and pushes as OCI-artifact into container registry using oras tool.
In addition it also pushes the SBOM file generated from prefetch using cosign tool.

## Parameters
|name|description|default value|required|
|---|---|---|---|
|IMAGE|Reference of the OCI image build maven will produce.||true|
|SBOM_FILENAME|The SBOM file name generated in prefetch.|"sbom-cyclonedx.json"|true|
|PACKAGE_NAMESPACE|The product package name of the maven zip image produced for.|"package"|false|
|PREFETCH_INPUT|In case it is not empty, the prefetched content should be made available to the build.|""|false|

## Results
|name|description|
|---|---|
|IMAGE_DIGEST|Digest of the OCI-artifact just built|
|IMAGE_URL|Repository and tag where the built OCI-artifact was pushed|
|SBOM_BLOB_URL|Reference of SBOM blob digest of the attached SBOM for OCI-artifact|

## Workspaces
|name|description|optional|
|---|---|---|
|source|Workspace containing the source to do zip bundle and OCI push.|false|
