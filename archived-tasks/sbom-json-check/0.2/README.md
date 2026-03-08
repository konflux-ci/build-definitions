## Warning
This task is deprecated with set deprecation date on 2024-09-30. EC will report presence of this task as violation after this date and before only as warning, please remove it from you pipeline.

# sbom-json-check task

Verifies the integrity and security of the Software Bill of Materials (SBOM) file in JSON format using CyloneDX tool.

## Parameters
|name|description|default value|required|
|---|---|---|---|
|IMAGE_URL|Fully qualified image name to verify.||true|
|IMAGE_DIGEST|Image digest.||true|
|CA_TRUST_CONFIG_MAP_NAME|The name of the ConfigMap to read CA bundle data from.|trusted-ca|false|
|CA_TRUST_CONFIG_MAP_KEY|The name of the key in the ConfigMap that contains the CA bundle data.|ca-bundle.crt|false|

## Results
|name|description|
|---|---|
|TEST_OUTPUT|Tekton task test output.|
|IMAGES_PROCESSED|Images processed in the task.|


## Additional info

## Source repository for image:

https://github.com/konflux-ci/konflux-test

## Additional links:

* https://www.cisa.gov/sbom
* https://www.redhat.com/en/blog/how-red-hat-addressing-demand-develop-offerings-more-securely
* https://cyclonedx.org/
* https://owasp.org/
