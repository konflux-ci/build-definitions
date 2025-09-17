# fbc-target-index-pruning-check task

Ensures file-based catalog (FBC) components do not remove versions of operators already added to a released catalog. Pruning is allowed only in channels that contain dev-preview, pre-ga, or candidate in their names.

## Parameters
|name|description|default value|required|
|---|---|---|---|
|IMAGE_URL|Fully qualified image name.||true|
|IMAGE_DIGEST|Image digest.||true|
|TARGET_INDEX|Image name of target index, minus tag.|registry.redhat.io/redhat/redhat-operator-index|false|
|RENDERED_CATALOG_DIGEST|Digest for attached json file containing the FBC fragment's opm rendered catalog.||true|

## Results
|name|description|
|---|---|
|TEST_OUTPUT|Tekton task test output.|
|IMAGES_PROCESSED|Images processed in the task.|


## Additional info

### What this check does:
- Runs `opm render` on both FBC fragment and TARGET_INDEX:OCP_VERSION images.
- Compares the channel data of the FBC fragment and target index.
- Checks if the FBC fragment will remove channels or channel entries previously added to the target index.
- Allows pruning only in channels that contain dev-preview, pre-ga, or candidate in their names.

## Source repository for image:
https://github.com/konflux-ci/konflux-test

## Additional links:
https://olm.operatorframework.io/docs/reference/file-based-catalogs/
https://github.com/containers/skopeo
https://docs.openshift.com/container-platform/4.12/cli_reference/opm/cli-opm-install.html
