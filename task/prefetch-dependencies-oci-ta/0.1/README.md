# prefetch-dependencies-oci-ta task

Task that uses Cachi2 to prefetch build dependencies. The fetched dependencies and the
application source code are stored as a trusted artifact in the provided OCI repository.
For additional info on Cachi2, see docs at
https://github.com/containerbuildsystem/cachi2#basic-usage.

## Parameters
|name|description|default value|required|
|---|---|---|---|
|input|Configures project packages that will have their dependencies prefetched.||true|
|source-artifact|The trusted artifact URI containing the application source code.||true|
|oci-storage|The OCI repository where the trusted artifacts with the modified cloned repository and the prefetched depedencies will be stored.||true|
|oci-artifact-expires-after|Expiration date for the trusted artifacts created in the OCI repository. An empty string means the artifacts do not expire.|""|false|
|dev-package-managers|Enable in-development package managers. WARNING: the behavior may change at any time without notice. Use at your own risk. |false|false|
|log-level|Set cachi2 log level (debug, info, warning, error)|info|false|
|caTrustConfigMapName|The name of the ConfigMap to read CA bundle data from.|trusted-ca|false|
|caTrustConfigMapKey|The name of the key in the ConfigMap that contains the CA bundle data.|ca-bundle.crt|false|

## Results
|name|description|
|---|---|
|source-artifact|The trusted artifact URI containing the modified application source.|
|cachi2-artifact|The trusted artifact URI containing the fetched dependencies.|

## Workspaces
|name|description|optional|
|---|---|---|
|git-basic-auth|A Workspace containing a .gitconfig and .git-credentials file or username and password. These will be copied to the user's home before any cachi2 commands are run. Any other files in this Workspace are ignored. It is strongly recommended to bind a Secret to this Workspace over other volume types. |true|
