# fbc-fips-check task

## Description:
The fbc-fips-check task uses the check-payload tool to verify if an unreleased operator bundle in an FBC fragment image is FIPS compliant.
It only scans operator bundle images which either claim to be FIPS compliant by setting the `features.operators.openshift.io/fips-compliant`
label to `"true"` on the bundle image or require one of `OpenShift Kubernetes Engine, OpenShift Platform Plus or OpenShift Container Platform`
subscriptions to run the operator on an Openshift cluster. 

This task extracts relatedImages from all unreleased operator bundle images from your FBC fragment and scans them. In the context of FBC fragment, an unreleased operator bundle image is the one that isn't currently present in the Red Hat production Index Image (`registry.redhat.io/redhat/redhat-operator-index`). It is necessary for relatedImages pullspecs to be pullable at build time of the FBC fragment.

In order to resolve them, this task expects a ImageDigestMirrorSet file located at .tekton/images-mirror-set.yaml of your FBC fragment git repo. It should map unreleased registry.redhat.io pullspecs of relatedImages to their valid quay.io pullspecs. If the ImageDigestMirrorSet is not provided, the task will attempt to process the registry.redhat.io pullspecs as is and might fail.

Here's an example of how the file should look like

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

## Params:

| name                     | description                                                            | default       |
|--------------------------|------------------------------------------------------------------------|---------------|
| image-digest             | Image digest to scan.                                                  | None          |
| image-url                | Image URL.                                                             | None          |

## Results:

| name               | description                  |
|--------------------|------------------------------|
| TEST_OUTPUT        | Tekton task test output.     |
| IMAGES_PROCESSED   | Images processed in the task.|


## Additional links:
* https://github.com/openshift/check-payload
* https://docs.openshift.com/container-platform/4.16/rest_api/config_apis/imagedigestmirrorset-config-openshift-io-v1.html
