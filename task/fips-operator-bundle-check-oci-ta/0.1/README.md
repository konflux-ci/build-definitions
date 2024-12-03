# fips-operator-bundle-check-oci-ta task

The fips-operator-bundle-check task uses the check-payload tool to verify if an operator bundle image is FIPS compliant. It only scans operator bundle images which either claim to be FIPS compliant by setting the `features.operators.openshift.io/fips-compliant` label to `"true"` on the bundle image or require one of `OpenShift Kubernetes Engine, OpenShift Platform Plus or OpenShift Container Platform` subscriptions to run the operator on an Openshift cluster. This task extracts relatedImages from the operator bundle image and scans them. Hence, it is necessary for relatedImages pullspecs to be pullable at build time. In order to resolve them, this task expects a `imageDigestMirrorSet` file located at `.tekton/images-mirror-set.yaml` of your operator bundle git repo. It should map unreleased `registry.redhat.io` pullspecs of relatedImages to their valid `quay.io` pullspecs.

## Parameters
|name|description|default value|required|
|---|---|---|---|
|SOURCE_ARTIFACT|The Trusted Artifact URI pointing to the artifact with the application source code.||true|
|image-digest|Image digest to scan.||true|
|image-url|Image URL.||true|

## Results
|name|description|
|---|---|
|IMAGES_PROCESSED|Images processed in the task.|
|TEST_OUTPUT|Tekton task test output.|

