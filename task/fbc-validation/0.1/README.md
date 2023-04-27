# fbc-validation task

## Description:
The fbc-validation task will ensure FBC (File based catalog) components uniquely linted to ensure they're properly
constructed as part of the build pipeline. To validate the image in build pipeline, Skopeo is used to extract
information and then contents are checked using the OpenShift Operator Framework.

## Params:

| name         | description                 |
|--------------|-----------------------------|
| image-digest | Image digest.               |
| image-url    | Fully qualified image name. |

## Params:

| name               | description               |
|--------------------|---------------------------|
| TEST_OUTPUT  | Tekton task test output.  |

## Source repository for image:
https://github.com/redhat-appstudio/hacbs-test

## Additional links:
https://olm.operatorframework.io/docs/reference/file-based-catalogs/
https://github.com/containers/skopeo
https://docs.openshift.com/container-platform/4.12/cli_reference/opm/cli-opm-install.html
