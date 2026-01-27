# sast-snyk-check task

Scans source code for security vulnerabilities, including common issues such as SQL injection, cross-site scripting (XSS), and code injection attacks using Snyk Code, a Static Application Security Testing (SAST) tool.

Follow the steps given [here](https://konflux-ci.dev/docs/testing/build/snyk/) to obtain a snyk-token and to enable the snyk task in a Pipeline.

The snyk binary used in this Task comes from a container image defined in https://github.com/konflux-ci/konflux-test

See https://snyk.io/product/snyk-code/ and https://snyk.io/ for more information about the snyk tool.

## Parameters
|name|description|default value|required|
|---|---|---|---|
|SNYK_SECRET|Name of secret which contains Snyk token.|snyk-secret|false|
|ARGS|Append arguments.|""|false|
|image-url|Image URL.||true|
|image-digest|Digest of the image to scan.||true|
|caTrustConfigMapName|The name of the ConfigMap to read CA bundle data from.|trusted-ca|false|
|caTrustConfigMapKey|The name of the key in the ConfigMap that contains the CA bundle data.|ca-bundle.crt|false|
|IMP_FINDINGS_ONLY|Report only important findings. Default is true. To report all findings, specify "false"|true|false|
|KFP_GIT_URL|Known False Positives (KFP) git URL (optionally taking a revision delimited by \#). Defaults to "SITE_DEFAULT", which means the default value "https://gitlab.cee.redhat.com/osh/known-false-positives.git" for internal Konflux instance and empty string for external Konflux instance. If set to an empty string, the KFP filtering is disabled.|SITE_DEFAULT|false|
|PROJECT_NAME|Name of the scanned project, used to find path exclusions. By default, the Konflux component name will be used.|""|false|
|TARGET_DIRS|Target directories in component's source code. Multiple values should be separated with commas.|.|false|
|RECORD_EXCLUDED|Write excluded records in file. Useful for auditing (defaults to false).|false|false|
|IGNORE_FILE_PATHS|Directories or files to be excluded from Snyk scan (Comma-separated). Useful to split the directories of a git repo across multiple components.|""|false|

## Results
|name|description|
|---|---|
|TEST_OUTPUT|Tekton task test output.|

## Workspaces
|name|description|optional|
|---|---|---|
|workspace||false|

## Additional info

> NOTE: For path exclusions defined in the known-false-positives (KFP) repo to be applied to scan results, the component name should match the respective directory in KFP. By default this is sourced from the `"appstudio.openshift.io/component"` label, but the `PROJECT_NAME` parameter can be used to override this.

## How to obtain a snyk-token and enable snyk task on the pipeline:

Follow the steps given [here](https://konflux-ci.dev/docs/testing/build/snyk/)

## Source repository for image:

<https://github.com/konflux-ci/konflux-test>

## Additional links:

* <https://snyk.io/product/snyk-code/>
* <https://snyk.io/>
