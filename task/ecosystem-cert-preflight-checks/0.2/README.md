# ecosystem-cert-preflight-checks task

## Description:

The ecosystem-cert-preflight-checks task checks an image for certification
readiness. This will run `preflight check container` against application images,
and will SKIP operator bundle images.

The image's type is introspected based on the image's labels if not set
explicitly to the desired type.

## Params:

| name                            | description                                                                                 | default                                                                      |
|---------------------------------|---------------------------------------------------------------------------------------------|------------------------------------------------------------------------------|
| image-url                       | Image URL.                                                                                  | None                                                                         |
| ca-trust-config-map-name        | The name of the ConfigMap to read CA bundle data from.                                      | trusted-ca                                                                   |
| ca-trust-config-map-key         | The name of the key in the ConfigMap that contains the CA bundle data.                      | ca-bundle.crt                                                                |
| artifact-type                   | The type of artifact. Select from application, operatorbundle, or introspect.               | introspect                                                                   |

## Results:

| name                 | description                                               |
|----------------------|-----------------------------------------------------------|
| TEST_OUTPUT          | Indicates whether the image passed ecosystem checks.      |
| ARTIFACT_TYPE        | The type of artifact that was checked.                    |
| ARTIFACT_TYPE_SET_BY | How the artifact's type was determined. Informational.    |

## Source repository for preflight:
https://github.com/redhat-openshift-ecosystem/openshift-preflight

## Additional links:
https://connect.redhat.com/en/blog/topic/preflight
