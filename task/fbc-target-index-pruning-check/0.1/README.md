# fbc-target-index-pruning-check task

## Description:
This task ensures file-based catalog (FBC) components do not remove previously released versions of operators from a target catalog, specified in the `TARGET_INDEX` parameter, which by default points to the Red Hat production Index Image `registry.redhat.io/redhat/redhat-operator-index`. Image pull credentials are required for `registry.redhat.io` or the registry you specify in `TARGET_INDEX`.

### What this check does:
- Runs `opm render` on both FBC fragment and TARGET_INDEX:OCP_VERSION images.
- Compares the channel data of the FBC fragment and target index.
- Checks if the FBC fragment will remove channels or channel entries previously added to the target index.


## Params:

| name         | description                      | default value |
|--------------|----------------------------------|---------|
| IMAGE_URL    | Fully qualified image name.      | |
| IMAGE_DIGEST | Image digest.                    | |
| TARGET_IMAGE | Image name of target index, minus tag. | `registry.redhat.io/redhat/redhat-operator-index` |
| RENDERED_CATALOG_DIGEST | Digest for attached json file containing the FBC fragment's opm rendered catalog. | |

## Results:

| name               | description               |
|--------------------|---------------------------|
| TEST_OUTPUT | Tekton task test output. |
| IMAGES_PROCESSED | Images processed in the task. |

## Source repository for image:
https://github.com/konflux-ci/konflux-test

## Additional links:
https://olm.operatorframework.io/docs/reference/file-based-catalogs/
https://github.com/containers/skopeo
https://docs.openshift.com/container-platform/4.12/cli_reference/opm/cli-opm-install.html
