# sast-unicode-check-oci-ta task

Scans source code for non-printable unicode characters in all text files.

## Parameters
|name|description|default value|required|
|---|---|---|---|
|CACHI2_ARTIFACT|The Trusted Artifact URI pointing to the artifact with the prefetched dependencies.|""|false|
|FIND_UNICODE_CONTROL_ARGS|arguments for find-unicode-control command.|-p bidi -v -d -t|false|
|FIND_UNICODE_CONTROL_GIT_URL|URL from repository to find unicode control.|https://github.com/siddhesh/find-unicode-control.git#c2accbfbba7553a8bc1ebd97089ae08ad8347e58|false|
|KFP_GIT_URL|Known False Positives (KFP) git URL (optionally taking a revision delimited by \#). Defaults to "SITE_DEFAULT", which means the default value "https://gitlab.cee.redhat.com/osh/known-false-positives.git" for internal Konflux instance and empty string for external Konflux instance. If set to an empty string, the KFP filtering is disabled.|SITE_DEFAULT|false|
|PROJECT_NAME|Name of the scanned project, used to find path exclusions. By default, the Konflux component name will be used.|""|false|
|RECORD_EXCLUDED|Whether to record the excluded findings (defaults to false). If `true`, the excluded findings will be stored in `excluded-findings.json`. |false|false|
|SOURCE_ARTIFACT|The Trusted Artifact URI pointing to the artifact with the application source code.||true|
|caTrustConfigMapKey|The name of the key in the ConfigMap that contains the CA bundle data.|ca-bundle.crt|false|
|caTrustConfigMapName|The name of the ConfigMap to read CA bundle data from.|trusted-ca|false|
|image-digest|Image digest used for ORAS upload.||true|
|image-url|Image URL used for ORAS upload.||true|

## Results
|name|description|
|---|---|
|TEST_OUTPUT|Tekton task test output.|

