# ecosystem-cert-preflight-checks task

## Description:

The ecosystem-cert-preflight-checks task checks an image for certification readiness.

## Params:

| name         | description                                                    |
|--------------|----------------------------------------------------------------|
| image-url    | Image URL.                                                     |

## Results:

| name              | description                                      |
|-------------------|--------------------------------------------------|
| TEST_OUTPUT       | Indicates whether the container passsed preflight|

## Source repository for preflight:
https://github.com/redhat-openshift-ecosystem/openshift-preflight

## Additional links:
https://connect.redhat.com/en/blog/topic/preflight
