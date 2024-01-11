# generate-odcs-compose task

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

Element fields:

* kind: Corresponds to sub-types of [`ComposeSourceGeneric`][input structure].
* spec: keyword arguments related to the compose source
* additional_args: flat-list of additional compose keyword arguments.

Example:

composes:
    - kind: ComposeSourceModule
      spec:
        modules:
          - squid:4:8090020231130092412:a75119d5
      additional_args: {}

[input structure]: https://pagure.io/odcs/blob/master/f/client/odcs/client/odcs.py#_115


## Params:

| name            | description                                                       |
|-----------------|-------------------------------------------------------------------|
| IMAGE           | Image used for running the tasks's script                         |
| COMPOSE_INPUTS  | relative path from workdir workspace to the compose inputs file   |
| COMPOSE_OUTPUTS | relative path from workdir workspace to store compose output files|
| KT_PATH         | Path to mount keytab to be used for authentication with ODCS      |
| KRB_CACHE_PATH  | Path to store Kerberos cache                                      |


## Results:

| name              | description                                  |
|-------------------|----------------------------------------------|
| repodir_path      | Directory to write the resulting .repo files |

## Source repository for image:
https://github.com/redhat-appstudio/tools

## Source repository for task:
https://github.com/redhat-appstudio/tekton-tools
