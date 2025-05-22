# coverity-availability-check-oci-ta task

This task performs needed checks in order to use Coverity image in the pipeline. It will check for a Coverity license secret and an authentication secret for pulling the image.

## Parameters
|name|description|default value|required|
|---|---|---|---|
|AUTH_TOKEN_COVERITY_IMAGE|Name of secret which contains the authentication token for pulling the Coverity image.|auth-token-coverity-image|false|
|CACHI2_ARTIFACT|The Trusted Artifact URI pointing to the artifact with the prefetched dependencies.|""|false|
|COV_LICENSE|Name of secret which contains the Coverity license|cov-license|false|
|SOURCE_ARTIFACT|The Trusted Artifact URI pointing to the artifact with the application source code.||true|

## Results
|name|description|
|---|---|
|STATUS|Tekton task simple status to be later checked|
|TEST_OUTPUT|Tekton task result output.|

