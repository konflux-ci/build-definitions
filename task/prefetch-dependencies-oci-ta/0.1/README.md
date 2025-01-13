# prefetch-dependencies-oci-ta task

Task that uses Cachi2 to prefetch build dependencies. The fetched dependencies and the
application source code are stored as a trusted artifact in the provided OCI repository.
For additional info on Cachi2, see docs at
https://github.com/containerbuildsystem/cachi2#basic-usage.

## Configuration

Config file must be passed as a YAML string. For all available config options please check
[available configuration parameters] page.

Example of setting timeouts:

```yaml
params:
  - name: config-file-content
    value: |
      ---
      requests_timeout: 300
      subprocess_timeout: 3600
```

[available configuration parameters]: https://github.com/containerbuildsystem/cachi2?tab=readme-ov-file#available-configuration-parameters

## Parameters
|name|description|default value|required|
|---|---|---|---|
|ACTIVATION_KEY|Name of secret which contains subscription activation key|activation-key|false|
|SOURCE_ARTIFACT|The Trusted Artifact URI pointing to the artifact with the application source code.||true|
|caTrustConfigMapKey|The name of the key in the ConfigMap that contains the CA bundle data.|ca-bundle.crt|false|
|caTrustConfigMapName|The name of the ConfigMap to read CA bundle data from.|trusted-ca|false|
|config-file-content|Pass configuration to cachi2. Note this needs to be passed as a YAML-formatted config dump, not as a file path! |""|false|
|dev-package-managers|Enable in-development package managers. WARNING: the behavior may change at any time without notice. Use at your own risk. |false|false|
|input|Configures project packages that will have their dependencies prefetched.||true|
|log-level|Set cachi2 log level (debug, info, warning, error)|info|false|
|ociArtifactExpiresAfter|Expiration date for the trusted artifacts created in the OCI repository. An empty string means the artifacts do not expire.|""|false|
|ociStorage|The OCI repository where the Trusted Artifacts are stored.||true|
|sbom-type|Select the SBOM format to generate. Valid values: spdx, cyclonedx.|cyclonedx|false|

## Results
|name|description|
|---|---|
|CACHI2_ARTIFACT|The Trusted Artifact URI pointing to the artifact with the prefetched dependencies.|
|SOURCE_ARTIFACT|The Trusted Artifact URI pointing to the artifact with the application source code.|

## Workspaces
|name|description|optional|
|---|---|---|
|git-basic-auth|A Workspace containing a .gitconfig and .git-credentials file or username and password. These will be copied to the user's home before any cachi2 commands are run. Any other files in this Workspace are ignored. It is strongly recommended to bind a Secret to this Workspace over other volume types. |true|
|netrc|Workspace containing a .netrc file. Cachi2 will use the credentials in this file when performing http(s) requests. |true|
