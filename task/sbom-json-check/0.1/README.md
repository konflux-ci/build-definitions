# sbom-json-check task

## Deprecation notice

This task is deprecated, please remove it from you pipeline.

## Description:

The sbom-json-check task verifies the integrity and security of a Software Bill of Materials (SBOM) file in JSON format using the CyloneDX tool.

The syntax of the sbom-cyclonedx.json file (found in the `/root/buildinfo/content_manifests/` directory) is checked using the CyloneDX tool, which is being led by longtime security community leader Open Web Application Security Project (OWASP). CycloneDX is a self-defined “lightweight SBOM standard designed for use in application security contexts and supply chain component analysis.”

## Params:

| name                     | description                                                            | default       |
|--------------------------|------------------------------------------------------------------------|---------------|
| IMAGE_URL                | Fully qualified image name to verify.                                  | None          |
| IMAGE_DIGEST             | Image digest.                                                          | None          |
| CA_TRUST_CONFIG_MAP_NAME | The name of the ConfigMap to read CA bundle data from.                 | trusted-ca    |
| CA_TRUST_CONFIG_MAP_KEY  | The name of the key in the ConfigMap that contains the CA bundle data. | ca-bundle.crt |

## Results:

| name                  | description              |
|-----------------------|--------------------------|
| TEST_OUTPUT     | Tekton task test output. |

## Source repository for image:

https://github.com/konflux-ci/konflux-test

## Additional links:

* https://www.cisa.gov/sbom
* https://www.redhat.com/en/blog/how-red-hat-addressing-demand-develop-offerings-more-securely
* https://cyclonedx.org/
* https://owasp.org/
