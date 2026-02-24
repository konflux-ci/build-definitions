# prefetch-dependencies-oci-ta task

Task that prefetches project dependencies for hermetic build.

## Parameters
|name|description|default value|required|
|---|---|---|---|
|ACTIVATION_KEY|Name of secret which contains subscription activation key|activation-key|false|
|SOURCE_ARTIFACT|The Trusted Artifact URI pointing to the artifact with the application source code.||true|
|caTrustConfigMapKey|The name of the key in the ConfigMap that contains the CA bundle data.|ca-bundle.crt|false|
|caTrustConfigMapName|The name of the ConfigMap to read CA bundle data from.|trusted-ca|false|
|config-file-content|Pass configuration to the prefetch tool. Note this needs to be passed as a YAML-formatted config dump, not as a file path! |""|false|
|dev-package-managers|Enable in-development package managers. WARNING: the behavior may change at any time without notice. Use at your own risk. |false|false|
|input|Configures project packages that will have their dependencies prefetched.||true|
|log-level|Set prefetch tool log level (debug, info, warning, error)|info|false|
|mode|Control how input requirement violations are handled: strict (errors) or permissive (warnings).|strict|false|
|ociArtifactExpiresAfter|Expiration date for the trusted artifacts created in the OCI repository. An empty string means the artifacts do not expire.|""|false|
|ociStorage|The OCI repository where the Trusted Artifacts are stored.||true|
|sbom-type|Select the SBOM format to generate. Valid values: spdx, cyclonedx.|spdx|false|

## Results
|name|description|
|---|---|
|CACHI2_ARTIFACT|The Trusted Artifact URI pointing to the artifact with the prefetched dependencies.|
|SOURCE_ARTIFACT|The Trusted Artifact URI pointing to the artifact with the application source code.|

## Workspaces
|name|description|optional|
|---|---|---|
|git-basic-auth|A Workspace containing a .gitconfig and .git-credentials file or username and password. These will be copied to the user's home before prefetch is run. Any other files in this Workspace are ignored. It is strongly recommended to bind a Secret to this Workspace over other volume types. |true|
|netrc|Workspace containing a .netrc file. Prefetch will use the credentials in this file when performing http(s) requests. |true|

## Additional info
