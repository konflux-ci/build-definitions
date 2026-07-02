# validate-fbc task

Ensures file-based catalog (FBC) components are uniquely linted for proper construction as part of build pipeline. The manifest data of container images is checked using OpenShift Operator Framework's opm CLI tool. The target OCP version is determined by reading the com.redhat.fbc.openshift.version label, or by falling back to the base image tag if the label is missing. If the identified OCP version is fetched from label and is 4.15 or higher, the strict base image check is bypassed.

The `opm` binary executes directly from the `konflux-test` image, removing the dependency on extracting it from the `operator-registry` base image of the FBC fragment. 

## Parameters
|name|description|default value|required|
|---|---|---|---|
|IMAGE_URL|Fully qualified image name.||true|
|IMAGE_DIGEST|Image digest.||true|

## Results
|name|description|
|---|---|
|RELATED_IMAGE_ARTIFACT|The Trusted Artifact URI pointing to the artifact with the related images for the FBC fragment.|
|TEST_OUTPUT_ARTIFACT|The Trusted Artifact URI pointing to the artifact with the related images for the FBC fragment.|
|TEST_OUTPUT|Tekton task test output.|
|RELATED_IMAGES_DIGEST|Digest for attached json file containing related images|
|IMAGES_PROCESSED|Images processed in the task.|
|RENDERED_CATALOG_DIGEST|Digest for attached json file containing the FBC fragment's opm rendered catalog.|


## Additional info
