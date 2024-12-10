# fips-operator-bundle-check task

## Description:
The fbc-fips-check task uses the check-payload tool to verify if an unreleased operator bundle in an FBC fragment image is FIPS compliant.
It only scans operator bundle images which either claim to be FIPS compliant by setting the `features.operators.openshift.io/fips-compliant`
label to `"true"` on the bundle image or require one of `OpenShift Kubernetes Engine, OpenShift Platform Plus or OpenShift Container Platform`
subscriptions to run the operator on an Openshift cluster. 

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
https://github.com/openshift/check-payload