# clair-scan task

## Description:
The clair-scan task performs vulnerability scanning using Clair, an open source tool for performing static analysis
on container images. Clair is specifically designed for scanning container images for security issues by
analyzing the components of a container image and comparing them against Clair's vulnerability databases.

## Params:

| name         | description                                                    |
|--------------|----------------------------------------------------------------|
| image-digest | Image digest to scan.                                          |
| image-url    | Image URL.                                                     |
| docker-auth  | Folder where container authorization in config.json is stored. |

## Results:

| name              | description              |
|-------------------|--------------------------|
| HACBS_TEST_OUTPUT | Tekton task test output. |
| CLAIR_SCAN_RESULT | Clair scan result.       |

## Clair-action repository:
https://github.com/quay/clair-action

## Source repository for image:
https://github.com/redhat-appstudio/hacbs-test/tree/main/clair-in-ci

## Additional links:
https://quay.github.io/clair/whatis.html