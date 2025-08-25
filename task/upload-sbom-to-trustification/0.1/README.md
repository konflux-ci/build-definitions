# upload-sbom-to-trustification task

Upload an SBOM file to [Trustification] using the [BOMbastic] API.

[Trustification]: https://github.com/trustification/trustification
[BOMbastic]: https://github.com/trustification/trustification/tree/main/bombastic

## Configuration

This task requires some configuration and authentication secrets. By default, the task takes
them from a secret called `trustification-secret` that exists in the same namespace where the
task runs. You can override the secret name via the `TRUSTIFICATION_SECRET_NAME` param.

### trustification-secret

Required keys:
- bombastic_api_url: URL of the BOMbastic api host (e.g. https://sbom.trustification.dev)
- oidc_issuer_url: URL of the OIDC token issuer (e.g. https://sso.trustification.dev/realms/chicken)
- oidc_client_id: OIDC client ID
- oidc_client_secret: OIDC client secret

Optional keys:
- supported_cyclonedx_version: If the SBOM uses a higher CycloneDX version,
    `syft convert` to the supported version before uploading.

## Parameters
|name|description|default value|required|
|---|---|---|---|
|SBOMS_DIR|Directory containing SBOM files. The task will search for CycloneDX JSON SBOMs recursively in this directory and upload them all to Trustification. The path is relative to the 'sboms' workspace.|.|false|
|HTTP_RETRIES|Maximum number of retries for transient HTTP(S) errors|3|false|
|TRUSTIFICATION_SECRET_NAME|Name of the Secret containing auth and configuration|trustification-secret|false|
|FAIL_IF_TRUSTIFICATION_NOT_CONFIGURED|Should the task fail if the Secret does not contain the required keys? (Set "true" to fail, "false" to skip uploading and exit with success).|true|false|

## Workspaces
|name|description|optional|
|---|---|---|
|sboms|Directory containing the SBOMs to upload|false|

## Additional info
