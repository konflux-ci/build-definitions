# build-maven-zip task

Build-maven-zip task builds prefetched maven and npm artifacts into a OCI-artifact with zip bundle  and pushes the OCI-artifact into container registry.
In addition it will use the SBOM file in prefetch-task, pushes the SBOM file to same registry of zip oci-artifact using cosign tool.
Note that this task needs the output of prefetch-dependencies task. If it is not activated, there will not be any output from this task.

## Parameters
|name|description|default value|required|
|---|---|---|---|
|IMAGE|Reference of the OCI-Artifact this build task will produce.||true|
|EXPIRES_AFTER|Delete image tag after specified time. Empty means to keep the image tag. Time values could be something like 1h, 2d, 3w for hours, days, and weeks, respectively.|""|false|
|SBOM_SKIP_VALIDATION|Flag to enable or disable SBOM validation before save. Validation is optional - use this if you are experiencing performance issues.|false|false|
|caTrustConfigMapName|The name of the ConfigMap to read CA bundle data from.|trusted-ca|false|
|caTrustConfigMapKey|The name of the key in the ConfigMap that contains the CA bundle data.|ca-bundle.crt|false|

## Results
|name|description|
|---|---|
|IMAGE_DIGEST|Digest of the OCI-Artifact just built|
|IMAGE_URL|OCI-Artifact repository and tag where the built OCI-Artifact was pushed|
|IMAGE_REF|OCI-Artifact reference of the built OCI-Artifact|
|SBOM_BLOB_URL|Reference of SBOM blob digest to enable digest-based verification from provenance|
|TARBALL_FILES|List of tarball files to be pushed as OCI|

## Workspaces
|name|description|optional|
|---|---|---|
|source|Workspace containing the source code to build.|false|

## Additional info
