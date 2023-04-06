# init task

Initialize Pipeline Task, include flags for rebuild and auth. Generates image repository secret used by the PipelineRun.

## Parameters
|name|description|default value|required|
|---|---|---|---|
|image-url|Image URL for build by PipelineRun||true|
|rebuild|Rebuild the image if exists|false|false|
|skip-checks|skip checks against built image|false|false|
|pipelinerun-name|Name of current pipelinerun, should be "$(context.pipelineRun.name)"||true|
|pipelinerun-uid|UID of current pipelinerun, should be "$(context.pipelineRun.uid)"||true|
|shared-secret|Shared resource secret for accessing user-workload image repository|redhat-appstudio-user-workload|false|

## Results
|name|description|
|---|---|
|build|Defines if the image in param image-url should be built|
|container-registry-secret|Name of secret with credentials|

