# prefetch-dependencies task

Task that uses Cachi2 to prefetch build dependencies.
See docs at https://github.com/containerbuildsystem/cachi2#basic-usage.

## Parameters
|name|description|default value|required|
|---|---|---|---|
|input|Configures project packages that will have their dependencies prefetched.||true|
|hermetic|Controls if the dependencies will be prefetched.|false|false|
|SOURCE_ARTIFACT|The source trusted artifact URI.||true|
|OCI_STORAGE|The OCI repository where the modified cloned repository and prefetch depedencies will be stored.||true|
|IMAGE_EXPIRES_AFTER|Expiration date for the artifacts created in the OCI repository.|""|true|
