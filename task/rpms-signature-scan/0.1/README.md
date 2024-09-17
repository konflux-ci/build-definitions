# rpms-signature-scan.yaml task

## Description:
This tasks scans RPMs in an image and provide information about RPMs signatures.

It can be used in two modes. Depending on the value of parameter `FAIL_UNSIGNED`, it
will either fail any run that find unsigned RPMs, or only report its finding without
failing (the latter is useful when running inside a build pipeline which tests the use of RPMs before their official release).

## Params:

| Name            | Description                                                       | Defaults  |
|-----------------|-------------------------------------------------------------------|-----------|
| IMAGE           | Image used for running the tasks's script                         |           |
| INPUT           | A reference to a container image                                  |           |
| FAIL_UNSIGNED   | [true \| false] If true fail if unsigned RPMs were found          | false     |
| WORKDIR         | Directory for storing temporary files                             |           |


## Results:

| Name              | Description              |
|-------------------|--------------------------|
| TEST_OUTPUT       | Tekton task test output  |
| RPMS_DATA         | RPMs scanner results     |

## Source repository for image:
https://github.com/redhat-appstudio/tools

## Source repository for task:
https://github.com/redhat-appstudio/tekton-tools
