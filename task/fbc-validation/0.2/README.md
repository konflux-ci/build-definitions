# fbc-validation task

## Description:
Ensures file-based catalog (FBC) components are uniquely linted for proper construction as part of build pipeline.

For further information on how to use the task, see the USAGE.md file.

For troubleshooting assistance, see the TROUBLESHOOTING.md file.

## Params:

| name         | description                      |
|--------------|----------------------------------|
| IMAGE_DIGEST | Image digest.                    |
| IMAGE_URL    | Fully qualified image name.      |
| BASE_IMAGE   | Fully qualified base image name. |

## Results:

| name               | description               |
|--------------------|---------------------------|
| TEST_OUTPUT  | Tekton task test output.  |

## Source repository for image:
https://github.com/konflux-ci/konflux-test

## Additional links:
https://olm.operatorframework.io/docs/reference/file-based-catalogs/
https://github.com/containers/skopeo
https://docs.openshift.com/container-platform/4.12/cli_reference/opm/cli-opm-install.html
