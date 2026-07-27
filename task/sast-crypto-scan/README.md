# sast-shell-check task

The sast-crypto-scan task uses [rh-crypto-scanner-image](https://gitlab.cee.redhat.com/security-guild/crypto-scanning/rh-crypto-scanner-image) tool to perform Static Code Analysis in order to detect crypto assets being used.

It reports crypto algorithms in a CycloneDX format (cbom.json).

## Parameters

|name|description|default value|required|
|---|---|---|---|
|image-url|Image URL.|""|false|
|image-digest|Image digest to report findings for.|""|false|
|PROJECT_NAME|Name of the scanned project, used to find path exclusions. By default, the Konflux component name will be used.|""|false|
|TARGET_DIRS|Target directories in component's source code. Multiple values should be separated with commas.|.|false|
|SKIP_SBOM_GENERATION|Skip SBOM-related operations. This will likely cause EC policies to fail if enabled|false|false|
|SCAN_TIMEOUT|Timeout scan if it takes more than the time specified.|30m|false|
|caTrustConfigMapName|The name of the ConfigMap to read CA bundle data from.|trusted-ca|false|
|caTrustConfigMapKey|The name of the key in the ConfigMap that contains the CA bundle data.|ca-bundle.crt|false|

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

## Source repository for image

<https://github.com/rh-pvsec/crypto-finder-image>
<https://github.com/rh-pvsec/crypto-rules-image>

## Additional links

* <https://github.com/scanoss/crypto-finder>
* <https://github.com/opengrep/opengrep>

