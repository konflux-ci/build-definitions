# operator-sdk-generate-bundle task

Generate an OLM bundle using the operator-sdk

## Parameters
|name|description|default value|required|
|---|---|---|---|
|input-dir|Directory to read cluster-ready operator manifests from|deploy|false|
|channels|Comma-separated list of channels the bundle belongs to|alpha|false|
|kustomize-dir|Directory containing kustomize bases in a "bases" dir and a kustomization.yaml for operator-framework manifests |""|false|
|extra-service-accounts|Comma-seperated list of service account names, outside of the operator's Deployment account, that have bindings to {Cluster}Roles that should be added to the CSV |""|false|
|version|Semantic version of the operator in the generated bundle||true|
|package-name|Bundle's package name||true|
|additional-labels-file|A plain text file containing additional labels to append to the generated Dockerfile |""|false|

## Workspaces
|name|description|optional|
|---|---|---|
|source|Workspace with the source code|false|

## Additional info
