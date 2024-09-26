# clamav-scan task

## Description:
The clamav-scan task scans files for viruses and other malware using the ClamAV antivirus scanner.
ClamAV is an open-source antivirus engine that can be used to check for viruses, malware, and other malicious content.
The task will extract compiled code to compare it against the latest virus database to identify any potential threats.
The logs will provide both the version of ClamAV and the version of the database used in the comparison scan.

## Params:

| name                     | description                                                            | default       |
|--------------------------|------------------------------------------------------------------------|---------------|
| image-digest             | Image digest to scan.                                                  | None          |
| image-url                | Image URL.                                                             | None          |
| docker-auth              | Unused, should be removed in next task version.                        |               |
| ca-trust-config-map-name | The name of the ConfigMap to read CA bundle data from.                 | trusted-ca    |
| ca-trust-config-map-key  | The name of the key in the ConfigMap that contains the CA bundle data. | ca-bundle.crt |

## Results:

| name               | description               |
|--------------------|---------------------------|
| TEST_OUTPUT  | Tekton task test output.  |

## Source repository for image:
https://github.com/konflux-ci/konflux-test/tree/main/clamav

## Additional links:
https://docs.clamav.net/
