# ecosystem-cert-preflight-checks task

Scans container images for certification readiness. Note that running this against an operatorbundle will result in a skip, as bundle validation is not executed through this task.

## Parameters
|name|description|default value|required|
|---|---|---|---|
|image-url|Image url to scan.||true|
|ca-trust-config-map-name|The name of the ConfigMap to read CA bundle data from.|trusted-ca|false|
|ca-trust-config-map-key|The name of the key in the ConfigMap that contains the CA bundle data.|ca-bundle.crt|false|
|artifact-type|The type of artifact. Select from application, operatorbundle, or introspect.|introspect|false|
|platform|The platform the image is built on.|""|false|

## Results
|name|description|
|---|---|
|TEST_OUTPUT|Ecosystem checks pass or fail outcome.|
|ARTIFACT_TYPE|The artifact type, either introspected or set.|
|ARTIFACT_TYPE_SET_BY|How the artifact type was set.|
|IMAGES_PROCESSED|Collected image digests|


## Additional info

The ecosystem-cert-preflight-checks task checks an image for certification
readiness. This will run `preflight check container` against application images,
and will SKIP operator bundle images.

The image's type is introspected based on the image's labels if not set
explicitly to the desired type.

## Source repository for preflight:
https://github.com/redhat-openshift-ecosystem/openshift-preflight

## Additional links:
https://connect.redhat.com/en/blog/topic/preflight
