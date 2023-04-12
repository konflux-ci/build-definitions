# show-sbom task

## Description

The show-sbom task prints Software Bill of Materials (SBOM) for the built by the pipekine image.
Output is in JSON format created by the CyloneDX tool.
Skipped if build failed.

## Parameters

|name|description|default value|required|
|---|---|---|---|
| IMAGE_URL    | Fully qualified image name to verify. | N/A | true |
| IMAGE_DIGEST | Image digest.                         | N/A | true |

## Results:

None

## Workspaces

|name|description|optional|
|---|---|---|
|source|Workspace containing the source code and SBOM from the build.|false|
