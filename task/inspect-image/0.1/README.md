# inspect-image task

## Description:
The inspect-image task uses Skopeo to inspect and analyze manifest data from the target source image of a
container if it is built from scratch. If the target image has a direct base image, the task will also use Skopeo to inspect
that base image.

## Params:

| name         | description                                 |
|--------------|---------------------------------------------|
| IMAGE_URL    | Fully qualified image name.                 |
| IMAGE_DIGEST | Image digest.                               |
| DOCKER_AUTH  | Secret with config.json for container auth. |

## Results:

| name                  | description                            |
|-----------------------|----------------------------------------|
| BASE_IMAGE            | Base image source image is built from. |
| BASE_IMAGE_REPOSITORY | Base image repository URL.             |
| HACBS_TEST_OUTPUT     | Tekton task test output.               |

## Source repository for image:
https://github.com/redhat-appstudio/hacbs-test

## Additional links:
https://www.redhat.com/en/topics/containers/what-is-skopeo