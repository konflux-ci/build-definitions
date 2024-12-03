# sast-coverity-check-oci-ta task

Scans source code for security vulnerabilities, including common issues such as SQL injection, cross-site scripting (XSS), and code injection attacks using Coverity. At the moment, this task only uses the buildless mode, which does not build the project in order to analyze it.

## Parameters
|name|description|default value|required|
|---|---|---|---|
|AUTH_TOKEN_COVERITY_IMAGE|Name of secret which contains the authentication token for pulling the Coverity image.|auth-token-coverity-image|false|
|CACHI2_ARTIFACT|The Trusted Artifact URI pointing to the artifact with the prefetched dependencies.|""|false|
|COV_ANALYZE_ARGS|Arguments to be appended to the cov-analyze command|--enable HARDCODED_CREDENTIALS --security --concurrency --spotbugs-max-mem=4096|false|
|COV_LICENSE|Name of secret which contains the Coverity license|cov-license|false|
|IMP_FINDINGS_ONLY|Report only important findings. Default is true. To report all findings, specify "false"|true|false|
|KFP_GIT_URL|URL from repository to download known false positives files|""|false|
|PROJECT_NAME|Name of the scanned project, used to find path exclusions. By default, the Konflux component name will be used.|""|false|
|RECORD_EXCLUDED|Write excluded records in file. Useful for auditing (defaults to false).|false|false|
|SOURCE_ARTIFACT|The Trusted Artifact URI pointing to the artifact with the application source code.||true|
|caTrustConfigMapKey|The name of the key in the ConfigMap that contains the CA bundle data.|ca-bundle.crt|false|
|caTrustConfigMapName|The name of the ConfigMap to read CA bundle data from.|trusted-ca|false|
|image-digest|Image digest to report findings for.||true|
|image-url|Image URL.||true|

## Results
|name|description|
|---|---|
|TEST_OUTPUT|Tekton task test output.|

