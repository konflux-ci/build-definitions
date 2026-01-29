# deprecated-image-check task

Identifies the unmaintained and potentially insecure deprecated base images. Pyxis API collects metadata from image repository, and Conftest applies supplied policy to identify the deprecated images using that metadata.

## Parameters
|name|description|default value|required|
|---|---|---|---|
|POLICY_DIR|Path to directory containing Conftest policies.|/project/repository/|false|
|POLICY_NAMESPACE|Namespace for Conftest policy.|required_checks|false|
|BASE_IMAGES_DIGESTS|Digests of base build images.|""|false|
|IMAGE_URL|Fully qualified image name.||true|
|IMAGE_DIGEST|Image digest.||true|
|CA_TRUST_CONFIG_MAP_NAME|The name of the ConfigMap to read CA bundle data from.|trusted-ca|false|
|CA_TRUST_CONFIG_MAP_KEY|The name of the key in the ConfigMap that contains the CA bundle data.|ca-bundle.crt|false|

## Results
|name|description|
|---|---|
|TEST_OUTPUT|Tekton task test output.|
|IMAGES_PROCESSED|Images processed in the task.|


## Additional info

The deprecated-image-check checks for deprecated images that are no longer maintained and prone to security issues.
Image SBOM and BASE_IMAGES_DIGESTS param is used to determine which base images were used during build of the image.
It accomplishes this by verifying the data using Pyxis to query container image data and running Conftest using the
supplied conftest policy. Conftest is an open-source tool that provides a way to enforce policies written
in a high-level declarative language called Rego.

## Source repository for image

https://github.com/konflux-ci/konflux-test

## Additional links

https://catalog.redhat.com/api/containers/docs/
https://www.redhat.com/en/blog/gathering-security-data-container-images-using-pyxis-api
https://github.com/open-policy-agent/conftest
https://redhat-appstudio.github.io/docs.stonesoup.io/Documentation/main/concepts/testing_applications/sanity_tests.html#_deprecated_image_checks
