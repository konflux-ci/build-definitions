# clair-scan task

Scans container images for vulnerabilities using Clair, by comparing the components of container image against Clair's vulnerability databases.

## Parameters
|name|description|default value|required|
|---|---|---|---|
|image-digest|Image digest to scan.||true|
|image-url|Image URL.||true|
|docker-auth|unused, should be removed in next task version.|""|false|
|ca-trust-config-map-name|The name of the ConfigMap to read CA bundle data from.|trusted-ca|false|
|ca-trust-config-map-key|The name of the key in the ConfigMap that contains the CA bundle data.|ca-bundle.crt|false|

## Results
|name|description|
|---|---|
|TEST_OUTPUT|Tekton task test output.|
|SCAN_OUTPUT|Clair scan result.|
|IMAGES_PROCESSED|Images processed in the task.|
|REPORTS|Mapping of image digests to report digests|


## Additional info
## Clair-action repository:
https://github.com/quay/clair-action

## Source repository for image:
https://github.com/konflux-ci/konflux-test/tree/main/clair-in-ci

## Additional links:
https://quay.github.io/clair/whatis.html
