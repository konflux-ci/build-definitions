# clair-scan task

## Description:
The clair-scan task performs vulnerability scanning using Clair, an open source tool for performing static analysis
on container images. Clair is specifically designed for scanning container images for security issues by
analyzing the components of a container image and comparing them against Clair's vulnerability databases.

## Params:

| name         | description                                                     | default |
|--------------|-----------------------------------------------------------------|-|
| image-digest | Image digest to scan.                                           | None |
| image-url    | Image URL.                                                      | None |
| docker-auth  | unused, should be removed in next task version                  | |
| ca-trust-config-map-name|The name of the ConfigMap to read CA bundle data from.| trusted-ca |
| ca-trust-config-map-key |The name of the key in the ConfigMap that contains the CA bundle data.| ca-bundle.crt |

## Results:

| name              | description                              |
|-------------------|------------------------------------------|
| TEST_OUTPUT       | Tekton task test output.                 |
| SCAN_OUTPUT       | Clair scan result.                       |
| REPORTS           |Mapping of image digests to report digests|

## Clair-action repository:
https://github.com/quay/clair-action

## Source repository for image:
https://github.com/konflux-ci/konflux-test/tree/main/clair-in-ci

## Additional links:
https://quay.github.io/clair/whatis.html
