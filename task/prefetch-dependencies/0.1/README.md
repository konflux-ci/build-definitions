# prefetch-dependencies task

Task that uses Cachi2 to prefetch build dependencies.
See docs at https://github.com/containerbuildsystem/cachi2#basic-usage.

## Parameters
|name|description|default value|required|
|---|---|---|---|
|input|Configures project packages that will have their dependencies prefetched.||true|
|dev-package-managers|Enable in-development package managers. WARNING: the behavior may change at any time without notice. Use at your own risk. |false|false|

## Workspaces
|name|description|optional|
|---|---|---|
|source|Workspace with the source code, cachi2 artifacts will be stored on the workspace as well|false|
