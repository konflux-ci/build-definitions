# verify-source task

The verify-source Task verifies the SLSA source level of a git commit
by checking for a Verification Summary Attestation (VSA) stored as a
git note. This task does not explicitly clone the repository - it performs
the verification using the sourcetool verifycommit command.

WARNING: This task uses source-tool (https://github.com/slsa-framework/source-tool)
which is currently a proof-of-concept and under active development. It should
not be used in production environments. Additionally, it currently only supports
GitHub repositories and may encounter API rate limits without authentication.


## Parameters
|name|description|default value|required|
|---|---|---|---|
|url|Repository URL to verify.||true|
|revision|Commit SHA to verify.||true|

## Results
|name|description|
|---|---|
|SLSA_SOURCE_LEVEL_ACHIEVED|The SLSA source level achieved by this commit|
|TEST_OUTPUT|JSON formatted test results for SLSA verification|


## Additional info
