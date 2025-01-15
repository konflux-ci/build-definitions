# sast-snyk-check task

## Description:

The sast-snyk-check task uses Snyk Code tool to perform Static Application Security Testing (SAST) for Snyk, a popular cloud-native application security platform.

Snyk's SAST tool uses a combination of static analysis and machine learning techniques to scan an application's source code for potential security vulnerabilities, including common issues such as SQL injection, cross-site scripting (XSS), and code injection attacks.

> NOTE: This task is executed only if the user provides a Snyk token stored in a secret in their namespace. The name of the secret then needs to be supplied in the `snyk-secret` pipeline parameter.

## Params:

| name               | description                                                                                                                                      | default value | required |
|--------------------|--------------------------------------------------------------------------------------------------------------------------------------------------|---------------|----------|
| SNYK_SECRET        | Name of secret which contains Snyk token.                                                                                                        | snyk-secret   | true     |
| ARGS               | Append arguments.                                                                                                                                | ""            | false    |
| IGNORE_FILE_PATHS  | Directories or files to be excluded from Snyk scan (Comma-separated). Useful to split the directories of a git repo across multiple components.  | ""            | false    |
| IMP_FINDINGS_ONLY  | Report only important findings.  To report all findings, specify "false"                                                                         | true          | true     |
| KFP_GIT_URL        | Link to the known-false-positives repository. If left blank, results won't be filtered                                                           | ""            | false    |
| PROJECT_NAME       | Name of the scanned project, used to find path exclusions. By default, the Konflux component name will be used.                                  | ""            | false    |
| RECORD_EXCLUDED    | Write excluded records in file. Useful for auditing.                                                                                             | false         | false    |

## How to obtain a snyk-token and enable snyk task on the pipeline:

Follow the steps given [here](https://konflux-ci.dev/docs/how-tos/testing/build/snyk/)

## Results:

| name          | description                |
|---------------|----------------------------|
| TEST_OUTPUT   | Tekton task test output.   |

## Source repository for image:

https://github.com/konflux-ci/konflux-test

## Additional links:

* https://snyk.io/product/snyk-code/
* https://snyk.io/
