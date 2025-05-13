# sast-unicode-check task

## Description:

The sast-unicode-check task uses [find-unicode-control](https://github.com/siddhesh/find-unicode-control.git) tool to perform Static Application Security Testing (SAST) to look for non-printable unicode characters in all text files in a source tree.

## Parameters:

| name                         | description                                                                                                                                   | Default Value                                                                                   | Required |
|------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------|-------------------------------------------------------------------------------------------------|----------|
| FIND_UNICODE_CONTROL_GIT_URL | URL from repository to find unicode control.                                                                                                  | "https://github.com/siddhesh/find-unicode-control.git#c2accbfbba7553a8bc1ebd97089ae08ad8347e58" | No       |
| FIND_UNICODE_CONTROL_ARGS    | arguments for find-unicode-control command.                                                                                                   | "-p bidi -v -d -t"                                                                              | No       |
| KFP_GIT_URL                  | Known False Positives (KFP) git URL (optionally taking a revision delimited by \#). Defaults to "SITE_DEFAULT", which means the default value "https://gitlab.cee.redhat.com/osh/known-false-positives.git" for internal Konflux instance and empty string for external Konflux instance. If set to an empty string, the KFP filtering is disabled.|SITE_DEFAULT|false|
| PROJECT_NAME                 | Name of the scanned project, used to find path exclusions. If set to an empty string, the Konflux component name will be used.                | ""                                                                                              | No       |
| RECORD_EXCLUDED              | Whether to record the excluded findings (defaults to false). If `true`, the the excluded findings will be stored in `excluded-findings.json`. | "false"                                                                                         | No       |
| image-digest | Image digest that will be uploaded with ORAS control.                                                                                                  | | YES                                                                                          | true       |

For path exclusions defined in the known-false-positives (KFP) repo to be applied to scan results, the component name should match the respective directory in KFP. By default this is sourced from the `"appstudio.openshift.io/component"` label, but the `PROJECT_NAME` parameter can be used to override this.

## Results:

| name          | description                              |
|---------------|------------------------------------------|
| TEST_OUTPUT   | Tekton task test output.                 |

## Source repository for image:

<https://github.com/konflux-ci/konflux-test>

## Additional links:

* <https://github.com/siddhesh/find-unicode-control.git>
