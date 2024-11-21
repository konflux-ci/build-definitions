# Migration from 0.2 to 0.3

Version 0.3:

- The `IMP_FINDINGS_ONLY` parameter has been introduced and enabled by default with "true" value. Only high or critical vulnerabilities will be shown. This behavior can be disabled with "false" value.
- The scan results uploaded in the SARIF format now additionally contain source code snippets and `csdiff/v1` fingerprints for each finding.
- There are no default arguments as "--all-projects --exclude=test*,vendor,deps" are ignored by Snyk Code
- SARIF produced by Snyk Code is not included in the CI log.
- The `KFP_GIT_URL` parameter has been introduced to indicate the repository to filter false positives. If this variable is left empty, the results won't be filtered. At the same time, we can store all excluded findings in a file using the `RECORD_EXCLUDED` parameter and specify a name of project with the `PROJECT_NAME` to use specific filters.
- The stats of the snyk scan are embedded into the result's SARIF file

## Action from users

Renovate bot PR will be created with warning icon for a sast-snyk-check which is expected, no action from users are required.
