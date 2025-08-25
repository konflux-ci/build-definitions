# eaas-provision-space task

Provisions an ephemeral namespace on an EaaS cluster using a crossplane namespace claim. This namespace can then be used to provision other ephemeral environments for testing.

## Parameters
|name|description|default value|required|
|---|---|---|---|
|ownerKind|The type of resource that should own the generated namespace claim. Deletion of this resource will trigger deletion of the SpaceRequest. Supported values: `PipelineRun`, `TaskRun`.|PipelineRun|false|
|ownerName|The name of the resource that should own the generated namespace claim. This should either be passed the value of `$(context.pipelineRun.name)` or `$(context.taskRun.name)` depending on the value of `ownerKind`.||true|
|ownerUid|The uid of the resource that should own the generated namespace claim. This should either be passed the value of `$(context.pipelineRun.uid)` or `$(context.taskRun.uid)` depending on the value of `ownerKind`.||true|

## Results
|name|description|
|---|---|
|secretRef|Name of a Secret containing a kubeconfig used to access the provisioned space.|


## Additional info
