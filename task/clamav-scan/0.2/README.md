# clamav-scan task

## Description:

The clamav-scan task scans files for viruses and other malware using the ClamAV antivirus scanner.
ClamAV is an open-source antivirus engine that can be used to check for viruses, malware, and other malicious content.
The task will extract compiled code to compare it against the latest virus database to identify any potential threats.
The logs will provide both the version of ClamAV and the version of the database used in the comparison scan.

## Version 0.2:

On this version the sidecard is removed from the task and required tools (jq, oc ..) were added to the Clamav BD container image
this should fix the problem of timing out when task is scanning the database and improve the performance.

## --max-filesize:

Is set to the same value as the default value according to the ClamAV official Documentation.

https://wiki.debian.org/ClamAV

https://docs.clamav.net/manual/Development/tips-and-tricks.html?highlight=max-filesize#general-debugging

## Parameters

| name                     | description                                                            | default value | required |
| ------------------------ | ---------------------------------------------------------------------- | ------------- | -------- |
| image-digest             | Image digest to scan.                                                  |               | true     |
| image-url                | Image URL.                                                             |               | true     |
| docker-auth              | unused                                                                 | ""            | false    |
| ca-trust-config-map-name | The name of the ConfigMap to read CA bundle data from.                 | trusted-ca    | false    |
| ca-trust-config-map-key  | The name of the key in the ConfigMap that contains the CA bundle data. | ca-bundle.crt | false    |
| scan-threads             | Number of threads to run in clamscan parallel. Should be <= 8.         | 1             | false    |

## Results

| name             | description                   |
| ---------------- | ----------------------------- |
| TEST_OUTPUT      | Tekton task test output.      |
| IMAGES_PROCESSED | Images processed in the task. |

## Source repository for image:

https://github.com/konflux-ci/konflux-test/tree/main/clamav

## Additional links:

https://docs.clamav.net/
