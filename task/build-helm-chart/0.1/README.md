# build-helm-chart task

The task packages and pushes a Helm chart to an OCI repository.
As Helm charts require to have a semver-compatible version to be packaged, the
task relies on git tags in order to determine the chart version during runtime.

The task computes the version based on the git commit SHA distance from the latest
tag prefixed with the value of TAG_PREFIX. The value of that tag will be used as
the version's X.Y values, and the Z value will be computed by the commit's distance
from the tag, followed by an abbreviated SHA as build metadata.

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
