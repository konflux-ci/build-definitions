# provision-env-with-ephemeral-namespace task

> **Deprecated**: This task is deprecated, please remove it from your pipeline and replace it with
the eaas-provision-space task. Deprecation date: 2025-01-17

## Description:
This task generates a spaceRequest which in turn creates a namespace in the cluster.
The namespace is intended to be used to run integration tests for components, in
an ephemeral environment that will be completely clean of previous artifacts.


## Params:

| name            | description                                                       |
|-----------------|-------------------------------------------------------------------|
| KONFLUXNAMESPACE | The Namespace in which the pipeline runs in. Accessible using `$(context.pipelineRun.namespace)` within the pipelinerun   |
| PIPELINERUN_NAME | The name of the Pipelinerun this task is a part of. Accessible using `$(context.pipelineRun.name)` within the pipelinerun |
| PIPELINERUN_UID | The unique identifier of the Pipelinerun this task is a part of. Accessible using `$(context.pipelineRun.uid)` within the pipelinerun |


## Results:

| name       | description                                                             |
|-------------------|------------------------------------------------------------------|
| secretRef  | The name of the secret with a SA token that had admin permissions in the newly created namespace |


## Source repository for task:
https://github.com/redhat-appstudio/tekton-tools
