# sast-shell-check-oci-ta task

The sast-shell-check task uses [shellcheck](https://www.shellcheck.net/) tool to perform Static Application Security Testing (SAST), a popular cloud-native application security platform. This task leverages the shellcheck wrapper (csmock-plugin-shellcheck-core) to run shellcheck on a directory tree.
ShellCheck is a static analysis tool, gives warnings and suggestions for bash/sh shell scripts.

## Parameters
|name|description|default value|required|
|---|---|---|---|
|CACHI2_ARTIFACT|The Trusted Artifact URI pointing to the artifact with the prefetched dependencies.|""|false|
|IMP_FINDINGS_ONLY|Whether to include important findings only|true|false|
|KFP_GIT_URL|Known False Positives (KFP) git URL (optionally taking a revision delimited by \#). Defaults to "SITE_DEFAULT", which means the default value "https://gitlab.cee.redhat.com/osh/known-false-positives.git" for internal Konflux instance and empty string for external Konflux instance. If set to an empty string, the KFP filtering is disabled.|SITE_DEFAULT|false|
|PROJECT_NAME|Name of the scanned project, used to find path exclusions. By default, the Konflux component name will be used.|""|false|
|RECORD_EXCLUDED|Whether to record the excluded findings (default to false). If `true`, the excluded findings will be stored in `excluded-findings.json`. |false|false|
|SOURCE_ARTIFACT|The Trusted Artifact URI pointing to the artifact with the application source code.||true|
|caTrustConfigMapKey|The name of the key in the ConfigMap that contains the CA bundle data.|ca-bundle.crt|false|
|caTrustConfigMapName|The name of the ConfigMap to read CA bundle data from.|trusted-ca|false|
|image-digest|Image digest to report findings for.|""|false|
|image-url|Image URL.|""|false|

## Results
|name|description|
|---|---|
|TEST_OUTPUT|Tekton task test output.|

