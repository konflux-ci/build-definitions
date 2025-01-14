# sast-snyk-check-oci-ta task

Scans source code for security vulnerabilities, including common issues such as SQL injection, cross-site scripting (XSS), and code injection attacks using Snyk Code, a Static Application Security Testing (SAST) tool.

Follow the steps given [here](https://konflux-ci.dev/docs/how-tos/testing/build/snyk/) to obtain a snyk-token and to enable the snyk task in a Pipeline.

The snyk binary used in this Task comes from a container image defined in https://github.com/konflux-ci/konflux-test

See https://snyk.io/product/snyk-code/ and https://snyk.io/ for more information about the snyk tool.

## Parameters
|name|description|default value|required|
|---|---|---|---|
|ARGS|Append arguments.|""|false|
|CACHI2_ARTIFACT|The Trusted Artifact URI pointing to the artifact with the prefetched dependencies.|""|false|
|IGNORE_FILE_PATHS|Directories or files to be excluded from Snyk scan (Comma-separated). Useful to split the directories of a git repo across multiple components.|""|false|
|IMP_FINDINGS_ONLY|Report only important findings. Default is true. To report all findings, specify "false"|true|false|
|KFP_GIT_URL|URL from repository to download known false positives files|""|false|
|PROJECT_NAME|Name of the scanned project, used to find path exclusions. By default, the Konflux component name will be used.|""|false|
|RECORD_EXCLUDED|Write excluded records in file. Useful for auditing (defaults to false).|false|false|
|SNYK_SECRET|Name of secret which contains Snyk token.|snyk-secret|false|
|SOURCE_ARTIFACT|The Trusted Artifact URI pointing to the artifact with the application source code.||true|
|caTrustConfigMapKey|The name of the key in the ConfigMap that contains the CA bundle data.|ca-bundle.crt|false|
|caTrustConfigMapName|The name of the ConfigMap to read CA bundle data from.|trusted-ca|false|
|image-url|Image URL.|""|false|

## Results
|name|description|
|---|---|
|TEST_OUTPUT|Tekton task test output.|

