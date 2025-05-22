# ecosystem-cert-preflight-checks task

## Description:

The ecosystem-cert-preflight-checks task checks an image for certification readiness.

## Params:

| name                     | description                                                            | default       |
|--------------------------|------------------------------------------------------------------------|---------------|
| image-url                | Image URL.                                                             | None          |
| ca-trust-config-map-name | The name of the ConfigMap to read CA bundle data from.                 | trusted-ca    |
| ca-trust-config-map-key  | The name of the key in the ConfigMap that contains the CA bundle data. | ca-bundle.crt |

## Results:

| name              | description                                      |
|-------------------|--------------------------------------------------|
| TEST_OUTPUT       | Indicates whether the container passsed preflight|

## Source repository for preflight:
https://github.com/redhat-openshift-ecosystem/openshift-preflight

## Additional links:
https://connect.redhat.com/en/blog/topic/preflight
