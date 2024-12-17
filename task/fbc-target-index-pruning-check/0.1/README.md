# fbc-target-index-pruning-check task

## Description:
Ensures file-based catalog (FBC) components do not remove released versions of operators from the production catalog.

For further information on how to use the task, see the USAGE.md file.

## Params:

| name         | description                      | default value |
|--------------|----------------------------------|---------|
| IMAGE_URL    | Fully qualified image name.      | |
| IMAGE_DIGEST | Image digest.                    | |
| TARGET_IMAGE | Image name of target index, minus tag. | `registry.redhat.io/redhat/redhat-operator-index` |
| OCP_VERSION  | OCP version of FBC image. | |

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
