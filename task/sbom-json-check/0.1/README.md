# sbom-json-check task

## Description:

The sbom-json-check task verifies the integrity and security of a Software Bill of Materials (SBOM) file in JSON format using the CyloneDX tool.

The syntax of the sbom-cyclonedx.json file (found in the `/root/buildinfo/content_manifests/` directory) is checked using the CyloneDX tool, which is being led by longtime security community leader Open Web Application Security Project (OWASP). CycloneDX is a self-defined “lightweight SBOM standard designed for use in application security contexts and supply chain component analysis.”

## Params:

| name         | description                           |
|--------------|---------------------------------------|
| IMAGE_URL    | Fully qualified image name to verify. |
| IMAGE_DIGEST | Image digest.                         |

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
