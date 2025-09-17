# verify-signed-rpms.yaml task

## Deprecation notice

This task is deprecated with set deprecation date on 2025-03-15.

As it was never included in any Conforma policy under the current name, there are no
expected changes in the way violations are reported for using the task.

Please use [task rpms-signature-scan](https://quay.io/repository/konflux-ci/tekton-catalog/task-rpms-signature-scan) instead.

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
