# sast-unicode-check task

## Description:

The sast-unicode-check task uses [find-unicode-control](https://github.com/siddhesh/find-unicode-control.git) tool to perform Static Application Security Testing (SAST) to look for non-printable unicode characters in all text files in a source tree.

## Parameters:

| name                         | description                                                                                                                                   | Default Value                                                                                   | Required |
|------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------|-------------------------------------------------------------------------------------------------|----------|
| FIND_UNICODE_CONTROL_GIT_URL | URL from repository to find unicode control.                                                                                                  | "https://github.com/siddhesh/find-unicode-control.git#c2accbfbba7553a8bc1ebd97089ae08ad8347e58" | No       |
| FIND_UNICODE_CONTROL_ARGS    | arguments for find-unicode-control command.                                                                                                   | "-p bidi -v -d -t"                                                                              | No       |
| KFP_GIT_URL                  | Known False Positives git URL, optionally taking a revision delimited by #; If empty, filtering of known false positives is disabled.         | ""                                                                                              | No       |
| PROJECT_NVR                  | Name-Version-Release (NVR) of the scanned project. It is used to find path exclusions (it is optional).                                       | ""                                                                                              | No       |
| RECORD_EXCLUDED              | Whether to record the excluded findings (defaults to false). If `true`, the the excluded findings will be stored in `excluded-findings.json`. | "false"                                                                                         | No       |

## Results:

| name          | description                              |
|---------------|------------------------------------------|
| TEST_OUTPUT   | Tekton task test output.                 |

## Source repository for image:

https://github.com/konflux-ci/konflux-test

## Additional links:

* https://github.com/siddhesh/find-unicode-control.git
