# fips-operator-bundle-check task

The fips-operator-bundle-check task uses the check-payload tool to verify if an operator bundle image is FIPS compliant. It only scans operator bundle images which either claim to be FIPS compliant by setting the `features.operators.openshift.io/fips-compliant` label to `"true"` on the bundle image or require one of `OpenShift Kubernetes Engine, OpenShift Platform Plus or OpenShift Container Platform` subscriptions to run the operator on an Openshift cluster. This task extracts relatedImages from the operator bundle image and scans them. Hence, it is necessary for relatedImages pullspecs to be pullable at build time. In order to resolve them, this task expects a `imageDigestMirrorSet` file located at `.tekton/images-mirror-set.yaml` of your operator bundle git repo. It should map unreleased `registry.redhat.io` pullspecs of relatedImages to their valid `quay.io` pullspecs.

## Parameters
|name|description|default value|required|
|---|---|---|---|
|image-digest|Image digest to scan.||true|
|image-url|Image URL.||true|
|MAX_PARALLEL|Maximum number of images to process in parallel|"8"|false|

## Results
|name|description|
|---|---|
|TEST_OUTPUT|Tekton task test output.|
|IMAGES_PROCESSED|Images processed in the task.|

## Workspaces
|name|description|optional|
|---|---|---|
|workspace||false|

## Additional info
### Parallel Processing
The MAX_PARALLEL parameter controls how many related images are scanned concurrently. The default value is "8", but this can be adjusted based on your resource availability and performance requirements. Increasing this value can speed up the scan for bundles with many related images, but may require more memory and CPU resources.

### Image Mirror Set
Here's an example of how the imageDigestMirrorSet file should look like:
```
---
apiVersion: operator.openshift.io/v1alpha1
kind: ImageDigestMirrorSet
metadata:
  name: example-mirror-set
spec:
  imageDigestMirrors:
    - mirrors:
        - quay.io/my-namespace/valid-repo
      source: registry.redhat.io/gatekeeper/gatekeeper
```

## Additional links:
https://github.com/openshift/check-payload
https://docs.openshift.com/container-platform/4.16/rest_api/config_apis/imagedigestmirrorset-config-openshift-io-v1.html
