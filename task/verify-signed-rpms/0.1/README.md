# verify-signed-rpms.yaml task

## Description:
This tasks checks whether the images it is provided with contain any unsigned RPMs.

It can be used in two modes. Depending on the value of parameter `FAIL_UNSIGNED`, it
will either fail any run that find unsigned RPMs, or only report its finding without
failing (the latter is useful when running inside a build pipeline which tests the use of RPMs before their official release).

## Params:

| name            | description                                                       |
|-----------------|-------------------------------------------------------------------|
| IMAGE           | Image used for running the tasks's script                         |
| INPUT           | AppStudio snapshot or a reference to a container image            |
| FAIL_UNSIGNED   | [true \| false] If true fail if unsigned RPMs were found          |
| WORKDIR         | directory for storing temporary files                             |


## Results:

| name              | description                               |
|-------------------|--------------------------|
| TEST_OUTPUT       | Tekton task test output. |

## Source repository for image:
https://github.com/redhat-appstudio/tools

## Source repository for task:
https://github.com/redhat-appstudio/tekton-tools
