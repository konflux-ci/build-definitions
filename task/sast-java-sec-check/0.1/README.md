# sast-java-sec-check task (Skipped)

## Description:

The sast-java-sec-check task makes use of FindSecBugs-CLI, which is a command-line interface tool for analyzing Java bytecode to identify security vulnerabilities. It is a part of the FindSecBugs project, which is an open-source security scanner for Java applications.

FindSecBugs-CLI uses a set of rules and checks to scan Java bytecode and generate a report of potential security issues. It supports various types of vulnerabilities, including SQL injection, cross-site scripting (XSS), deserialization vulnerabilities, and others.

> NOTE: This task is currently skipped.

## Params:

| name                | description                             |
|---------------------|-----------------------------------------|
| PATH_CONTEXT        | Path to your source code.               |
| OUTPUT_FORMAT       | Format of findsecbugs output.           |
| OUTPUT_ONLY_ANALYZE | Analyze only given classes and packages; Ending with .* to indicate classes in a package, .- to indicate a package prefix. |
| OPTIONAL_ARGS       | Optional parameters to run findsecbugs. |

## Results:

| name                  | description              |
|-----------------------|--------------------------|
| HACBS_TEST_OUTPUT     | Tekton task test output. |

## Source repository for image:

https://github.com/redhat-appstudio/hacbs-test

## Additional links:

* https://find-sec-bugs.github.io/
* https://find-sec-bugs.github.io/bugs.htm
