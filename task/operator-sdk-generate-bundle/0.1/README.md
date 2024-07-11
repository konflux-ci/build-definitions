# operator-sdk-generate-bundle task

Generate an OLM bundle using the operator-sdk

## Parameters
|name|description|default value|required|
|---|---|---|---|
|input-dir|Directory to read cluster-ready operator manifests from|deploy|false|
|channels|Comma-separated list of channels the bundle belongs to|alpha|false|
|version|Semantic version of the operator in the generated bundle||true|
|package-name|Bundle's package name||true|

## Workspaces
|name|description|optional|
|---|---|---|
|source|Workspace with the source code|false|
