# sast-coverity-check task

## Description:

The sast-coverity-check task uses Coverity tool to perform Static Application Security Testing (SAST).

The documentation for this mode can be found here: https://sig-product-docs.synopsys.com/bundle/coverity-docs/page/commands/topics/coverity_capture.html

The characteristics of these tasks are:

- Perform buildful scanning with Coverity
- Only important findings are reported by default.  A parameter ( `IMP_FINDINGS_ONLY`) is provided to override this configuration.
- The csdiff/v1 SARIF fingerprints are provided for all findings
- A parameter ( `KFP_GIT_URL`) is provided to remove false positives providing a known false positives repository. By default, no repository is provided.

> NOTE: This task is executed only if there is a Coverity license set up in the environment. Please check coverity-availability-check task for more information.

## Params:

| name                      | description                                                                                                                           | default value             | required |                                                                                                                   
|---------------------------|---------------------------------------------------------------------------------------------------------------------------------------|---------------------------|----------|
| COV_ANALYZE_ARGS          | Append arguments to the cov-analyze CLI command                                                                                       | ""                        | no       |
| COV_LICENSE               | Name of secret which contains the Coverity license                                                                                    | cov-license               | no       |
| AUTH_TOKEN_COVERITY_IMAGE | Name of secret which contains the authentication token for pulling the Coverity image                                                 | auth-token-coverity-image | no       |
| IMP_FINDINGS_ONLY         | Report only important findings. Default is true. To report all findings, specify "false"                                              | true                      | no       |
| KFP_GIT_URL               | Known False Positives git URL, optionally taking a revision delimited by #; If empty, filtering of known false positives is disabled. | ""                        | no       |
| PROJECT_NAME              | Name of the scanned project, used to find path exclusions. By default, the Konflux component name will be used.                       | ""                        | no       |
| RECORD_EXCLUDED           | If set to `true`, excluded findings will be written to a file named `excluded-findings.json` for auditing purposes.                   | false                     | no       |

## Results:

| name              | description              |
|-------------------|--------------------------|
| TEST_OUTPUT       | Tekton task test output. |

## Source repository for image:

// TODO: Add reference to private repo for the container image once the task is migrated to repo


## Additional links:

* https://sig-product-docs.synopsys.com/bundle/coverity-docs/page/commands/topics/coverity_capture.html
* https://sig-product-docs.synopsys.com/bundle/coverity-docs/page/cli/topics/options_reference.html
