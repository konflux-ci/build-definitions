# generate-odcs-compose task

> **Deprecated**: This task is deprecated. Please remove it from your pipeline.
  Deprecation date: 2025-03-15

## Description:
This task generates compose (yum repository) files that can be later on mounted during
build tasks and used for installing RPMs. It uses ODCS (On Demand Compose Service) for
generating composes.

The task takes inputs in [structure][input structure] defined by the ODCS Python client.

It stores the generated compose inside a directory provided as input, that can later on
be mounted during a build task.

The input is provided inside a YAML file with its root containing a single element
named `composes`. This element is a list in which each entry is to be converted
into inputs for a single call to ODCS.

The task requires a secret to reside on the namespace where the task is running.
The secret should be named `odcs-service-account` and it should include two fields:
`client-id` - containing an OIDC client ID and `client-secret` containing the client's
secret for generating OIDC token.

Element fields:

* kind: Corresponds to sub-types of [`ComposeSourceGeneric`][input structure].
* spec: keyword arguments related to the compose source
* additional_args: flat-list of additional compose keyword arguments.

Example:

```yaml
composes:
    - kind: ComposeSourceModule
      spec:
        modules:
          - squid:4:8090020231130092412:a75119d5
      additional_args: {}
```

[input structure]: https://pagure.io/odcs/blob/master/f/client/odcs/client/odcs.py#_115


## Params:

| Name            | Description                                         | Defaults                   |
| ---             | ---                                                 | ---                        |
| COMPOSE_INPUTS  | path from workdir workspace to compose inputs file  | source/compose_inputs.yaml |
| COMPOSE_OUTPUTS | path from workdir workspace to store compose output | fetched.repos.d            |


## Results:

| name              | description                                   |
| ---               | ---                                           |
| repodir_path      | Directory to write the resulting .repo files  |

## Source repository for image:
https://github.com/redhat-appstudio/tools

## Source repository for task (limited access):
https://github.com/redhat-appstudio/tekton-tools
