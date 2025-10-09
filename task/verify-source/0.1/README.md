# verify-source task

The verify-source Task verifies the SLSA source level of a git commit
by checking for a Verification Summary Attestation (VSA) stored as a
git note. This task does not explicitly clone the repository - it performs
the verification using the sourcetool verifycommit command.


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
