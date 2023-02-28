# clamav-scan task

## Description:
The clamav-scan task scans files for viruses and other malware using the ClamAV antivirus scanner.
ClamAV is an open-source antivirus engine that can be used to check for viruses, malware, and other malicious content.
The task will extract compiled code to compare it against the latest virus database to identify any potential threats.

## Params:

| name         | description                                                    |
|--------------|----------------------------------------------------------------|
| image-digest | Image digest to scan.                                          |
| image-url    | Image URL.                                                     |
| docker-auth  | Folder where container authorization in config.json is stored. |

## Params:

| name               | description               |
|--------------------|---------------------------|
| HACBS_TEST_OUTPUT  | Tekton task test output.  |

## Source repository for image:
https://github.com/redhat-appstudio/hacbs-test/tree/main/clamav

## Additional links:
https://docs.clamav.net/
