# deprecated-image-check task

## Description

The deprecated-image-check checks for deprecated images that are no longer maintained and prone to security issues.
Image SBOM and BASE_IMAGES_DIGESTS param is used to determine which base images were used during build of the image.
It accomplishes this by verifying the data using Pyxis to query container image data and running Conftest using the
supplied conftest policy. Conftest is an open-source tool that provides a way to enforce policies written
in a high-level declarative language called Rego.

## Params

| name                | description                                     |
|---------------------|-------------------------------------------------|
| POLICY_DIR          | Path to directory containing Conftest policies. |
| POLICY_NAMESPACE    | Namespace for Conftest policy.                  |
| BASE_IMAGES_DIGESTS | (Optional) Digests of base build images.        |
| IMAGE_DIGEST        | Image digest.                                   |
| IMAGE_URL           | Fully qualified image name.                     |

## Results

| name              | description                               |
|-------------------|-------------------------------------------|
| TEST_OUTPUT       | Tekton task test output.                  |

## Source repository for image

https://github.com/redhat-appstudio/hacbs-test

## Additional links

https://catalog.redhat.com/api/containers/docs/
https://www.redhat.com/en/blog/gathering-security-data-container-images-using-pyxis-api
https://github.com/open-policy-agent/conftest
https://redhat-appstudio.github.io/docs.stonesoup.io/Documentation/main/concepts/testing_applications/sanity_tests.html#_deprecated_image_checks
