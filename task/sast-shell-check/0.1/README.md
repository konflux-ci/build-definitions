# sast-shell-check task

## Description

The sast-shell-check task uses [shellcheck](https://www.shellcheck.net/) to perform Static Application Security Testing (SAST). This task leverages a shellcheck wrapper ([csmock-plugin-shellcheck-core](https://github.com/csutils/csmock)) to run shellcheck on a directory tree.

ShellCheck is a static analysis tool, gives warnings and suggestions for bash/sh shell scripts.

## Params

| Name              | Description                                                                                                                                            | Default Value | Required |
| ----------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------ | ------------- | -------- |
| KFP_GIT_URL       | Known False Positives (KFP) git URL (optionally taking a revision delimited by \#). Defaults to "SITE_DEFAULT", which means the default value "https://gitlab.cee.redhat.com/osh/known-false-positives.git" for internal Konflux instance and empty string for external Konflux instance. If set to an empty string, the KFP filtering is disabled.|SITE_DEFAULT|false|
| PROJECT_NAME      | Name of the scanned project, used to find path exclusions. By default, the Konflux component name will be used.                                        | ""            | No       |
| RECORD_EXCLUDED   | Whether to record the excluded findings to file, Useful for auditing.<br/>If "true", the excluded findings will be stored in `excluded-findings.json`. | "false"       | No       |
| IMP_FINDINGS_ONLY | Whether to report only important findings. To report all findings, specify "false".                                                                    | "true"        | No       |
| TARGET_DIRS       | Target directories in component's source code. Multiple values should be separated with commas.                                                        | "."           | No       |

For path exclusions defined in the known-false-positives (KFP) repo to be applied to scan results, the component name should match the respective directory in KFP. By default this is sourced from the `"appstudio.openshift.io/component"` label, but the `PROJECT_NAME` parameter can be used to override this.

## Results

| name        | description              |
| ----------- | ------------------------ |
| TEST_OUTPUT | Tekton task test output. |

## Source repository for image

<https://github.com/konflux-ci/konflux-test>

## Additional links

* <https://www.shellcheck.net/wiki/Home>
* <https://github.com/koalaman/shellcheck>
* <https://github.com/csutils/csmock>
