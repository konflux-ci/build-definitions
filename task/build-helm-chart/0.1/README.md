# build-helm-chart task

Package and push a Helm chart to an OCI repository

## Parameters
|name|description|default value|required|
|---|---|---|---|
|REPO|Designated registry for the chart to be pushed to||true|
|COMMIT_SHA|Git commit sha to build chart for|alpha|true|
|SOURCE_CODE_DIR|Path relative to the workingDir where the code was pulled into|source|false|
|CHART_CONTEXT|Path relative to SOURCE_CODE_DIR where the chart is located|dist/chart|false|
|VERSION_SUFFIX|A suffix to be added to the version string|""|false|
|TAG_PREFIX|An identifying prefix on which the version tag is to be matched|helm-|false|
|CA_TRUST_CONFIG_MAP_NAME|The name of the ConfigMap to read CA bundle data from.|trusted-ca|false|
|CA_TRUST_CONFIG_MAP_KEY|The name of the key in the ConfigMap that contains the CA bundle data.|ca-bundle.crt|false|

## Workspaces
|name|description|optional|
|---|---|---|
|source|Workspace with the source code|false|
