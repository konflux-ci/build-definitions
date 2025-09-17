# show-sbom-rhdh task

Shows the Software Bill of Materials (SBOM) generated for the built image. The 'task.*' annotations are processed by Red Hat Developer Hub (RHDH) so that the log content can be rendered in its UI.

## Parameters
|name|description|default value|required|
|---|---|---|---|
|IMAGE_URL|Fully qualified image name to show SBOM for.||true|

## Results
|name|description|
|---|---|
|LINK_TO_SBOM|Placeholder result meant to make RHDH identify this task as the producer of the SBOM logs.|


## Additional info
