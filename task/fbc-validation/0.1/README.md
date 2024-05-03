# fbc-validation task

## Description:
The fbc-validation task will ensure FBC (File based catalog) components uniquely linted to ensure they're properly
constructed as part of the build pipeline. To validate the image in build pipeline, Skopeo is used to extract
information from the image itself and then contents are checked using the OpenShift Operator Framework.  The binary
used to run the validation is extracted from the base image for the component being tested.  Because of this, the
base image must come from a trusted source.  Trusted sources are declared in `ALLOWED_BASE_IMAGES` in fbc-validation.yaml.

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
