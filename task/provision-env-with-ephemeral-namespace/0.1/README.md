# provision-env-with-ephemeral-namespace task

## Description:
This task generates a spaceRequest which in turn creates a namespace in the cluster.
The namespace is intended to be used to run integration tests for components, in
an ephemeral environment that will be completely clean of previous artifacts.


## Params:

| name               | description                                                       |
|--------------------|-------------------------------------------------------------------|
| KONFLUXNAMESPACE   | The namespace to create the spaceRequest from                     |
| SPACEREQUEST_NAME  | The name for the newly created space request                      |


## Results:

| name              | description                                                                                      |
|-------------------|--------------------------------------------------------------------------------------------------|
| secretRef         | The name of the secret with a SA token that had admin permissions in the newly created namespace |


## Source repository for task:
https://github.com/redhat-appstudio/tekton-tools


