# sast-coverity-check-oci-ta task

Scans source code for security vulnerabilities, including common issues such as SQL injection, cross-site scripting (XSS), and code injection attacks using Coverity.

## Parameters
|name|description|default value|required|
|---|---|---|---|
|CACHI2_ARTIFACT|The Trusted Artifact URI pointing to the artifact with the prefetched dependencies.|""|false|
|COV_ANALYZE_ARGS|Arguments to be appended to the cov-analyze command|--enable HARDCODED_CREDENTIALS --security --concurrency --spotbugs-max-mem=4096|false|
|COV_LICENSE|Name of secret which contains the Coverity license|cov-license|false|
|IMP_FINDINGS_ONLY|Report only important findings. Default is true. To report all findings, specify "false"|true|false|
|KFP_GIT_URL|Known False Positives (KFP) git URL (optionally taking a revision delimited by \#). Defaults to "SITE_DEFAULT", which means the default value "https://gitlab.cee.redhat.com/osh/known-false-positives.git" for internal Konflux instance and empty string for external Konflux instance. If set to an empty string, the KFP filtering is disabled.|SITE_DEFAULT|false|
|PROJECT_NAME||""|false|
|RECORD_EXCLUDED||false|false|
|SOURCE_ARTIFACT|The Trusted Artifact URI pointing to the artifact with the application source code.||true|
|caTrustConfigMapKey|The name of the key in the ConfigMap that contains the CA bundle data.|ca-bundle.crt|false|
|caTrustConfigMapName|The name of the ConfigMap to read CA bundle data from.|trusted-ca|false|

## Results
|name|description|
|---|---|
|TEST_OUTPUT|Tekton task test output.|

## Workspaces
|name|description|optional|
|---|---|---|
|sast-results|Workspace containing the SAST scanning results.|false|
