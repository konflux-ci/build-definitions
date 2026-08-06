# sast-crypto-scan-oci-ta task

The sast-crypto-scan-oci-ta task uses [crypto-finder-image](https://github.com/rh-pvsec/crypto-finder-image) tool to perform Static Code Analysis in order to detect crypto assets being used.

It reports crypto algorithms in a CycloneDX format (cbom.json).

## Parameters

|name|description|default value|required|
|---|---|---|---|
|CACHI2_ARTIFACT|The Trusted Artifact URI pointing to the artifact with the prefetched dependencies.|""|false|
|SOURCE_ARTIFACT|The Trusted Artifact URI pointing to the artifact with the application source code.||true|
|TARGET_DIRS|Target directories in component's source code. Multiple values should be separated with commas.|.|false|
|SKIP_SBOM_GENERATION|Skip SBOM-related operations. This will likely cause EC policies to fail if enabled|false|false|
|SCAN_TIMEOUT|Timeout scan if it takes more than the time specified.|30m|false|
|caTrustConfigMapKey|The name of the key in the ConfigMap that contains the CA bundle data.|ca-bundle.crt|false|
|caTrustConfigMapName|The name of the ConfigMap to read CA bundle data from.|trusted-ca|false|
|image-digest|Digest of the image to scan.|""|false|
|image-url|Image URL.|""|false|

## Results

|name|description|
|---|---|
|TEST_OUTPUT|Tekton task test output.|

## Source repository for image

<https://github.com/rh-pvsec/crypto-finder-image>
<https://github.com/rh-pvsec/crypto-rules-image>

## Additional links

* <https://github.com/scanoss/crypto-finder>
* <https://github.com/opengrep/opengrep>
