# deprecated-image-check task

## Deprecation notice

This task version is deprecated, please use the latest version.
Deprecation date: 2024-06-01

## Description:
The deprecated-image-check checks for deprecated images that are no longer maintained and prone to security issues.
It accomplishes this by verifying the data using Pyxis to query container image data and running Conftest using the
supplied conftest policy. Conftest is an open-source tool that provides a way to enforce policies written
in a high-level declarative language called Rego.

## Params:

| name                | description                                     |
|---------------------|-------------------------------------------------|
| POLICY_DIR          | Path to directory containing Conftest policies. |
| POLICY_NAMESPACE    | Namespace for Conftest policy.                  |
| BASE_IMAGES_DIGESTS | Digests of base build images.                   |

## Results:

| name              | description                               |
|-------------------|-------------------------------------------|
| PYXIS_HTTP_CODE   | HTTP code returned by Pyxis API endpoint. |
| TEST_OUTPUT | Tekton task test output.                  |

## Source repository for image:
https://github.com/konflux-ci/konflux-test

## Additional links:
https://catalog.redhat.com/api/containers/docs/
https://www.redhat.com/en/blog/gathering-security-data-container-images-using-pyxis-api
https://github.com/open-policy-agent/conftest
https://redhat-appstudio.github.io/docs.stonesoup.io/Documentation/main/concepts/testing_applications/sanity_tests.html#_deprecated_image_checks
