# coverity-availability-check task

## Description:

This task performs needed checks in order to use Coverity image in the pipeline. It will check for a Coverity license secret and an authentication secret for pulling the image.

The characteristics of these tasks are:

- It will check for a secret called "auth-token-coverity-image" where the authentication token for pulling Coverity image is pulled.
- It will check for a secret called "cov-license" where the Coverity license is stored.

> NOTE: If any of these tasks fails, the sast-coverity-task check won't be executed. The Coverity license can be used by Red Hat employees only and it needs to be protected such that external users cannot access the license.

## Params:

| name                        | description                                                                            | default value              | required |
|-----------------------------|----------------------------------------------------------------------------------------|----------------------------|----------|
| AUTH_TOKEN_COVERITY_IMAGE   | Name of secret which contains the authentication token for pulling the Coverity image  | auth-token-coverity-image  | yes      | 
| COV_LICENSE                 | Name of secret which contains the Coverity license                                     | cov-license                | yes      |                                                                    

## Results:

| name        | description                                                                       |
|-------------|-----------------------------------------------------------------------------------|
| STATUS      | Tekton task simple status to be later checked by the sast-coverity-check task     |
| TEST_OUTPUT | Tekton task test output.                                                          |
