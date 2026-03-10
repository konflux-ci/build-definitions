# fbc-fips-check-oci-ta task

The fbc-fips-check task uses the check-payload tool to verify if an unreleased operator bundle in an FBC fragment image is FIPS compliant. It only scans operator bundle images which either claim to be FIPS compliant by setting the `features.operators.openshift.io/fips-compliant` label to `"true"` on the bundle image or require one of `OpenShift Kubernetes Engine, OpenShift Platform Plus or OpenShift Container Platform` subscriptions to run the operator on an Openshift cluster.
This task extracts relatedImages from all unreleased operator bundle images from your FBC fragment and scans them. In the context of FBC fragment, an unreleased operator bundle image is the one that isn't currently present in the Red Hat production Index Image (`registry.redhat.io/redhat/redhat-operator-index`). It is necessary for relatedImages pullspecs to be pullable at build time of the FBC fragment.
In order to resolve them, this task expects an ImageDigestMirrorSet file at the path given by `image-mirror-set-path` (default: `.tekton/images-mirror-set.yaml`) of your FBC fragment git repo. It should map unreleased `registry.redhat.io` pullspecs of relatedImages to their valid quay.io pullspecs. If the ImageDigestMirrorSet is not provided, the task will attempt to process the registry.redhat.io pullspecs as is and might fail.

**Matrix mode (NUM_WORKERS > 1)**: This task prepares images and splits them into buckets for parallel processing with fbc-fips-check-worker-oci-ta tasks via matrix expansion.
**Inline mode (NUM_WORKERS = 1, default)**: This task performs the FIPS check directly, compatible with 0.1 behavior.

## Parameters
|name|description|default value|required|
|---|---|---|---|
|MAX_PARALLEL|Maximum number of images to process in parallel (used in inline mode)|8|false|
|NUM_WORKERS|Number of parallel workers. When 1 (default), runs FIPS check inline. When >1, enables matrix mode for parallel worker tasks.|1|false|
|SIZE_FETCH_PARALLEL|Number of parallel image size fetches for load balancing (used in matrix mode)|5|false|
|SOURCE_ARTIFACT|The Trusted Artifact URI pointing to the artifact with the application source code.||true|
|image-digest|Image digest to scan.||true|
|image-mirror-set-path|Path to the image mirror set file.|.tekton/images-mirror-set.yaml|false|
|image-url|Image URL.||true|
|output-image|Base image URL for storing artifacts (required for matrix mode)|""|false|

## Results
|name|description|
|---|---|
|IMAGES_PROCESSED|Images processed in the task.|
|TEST_OUTPUT|Tekton task test output.|
|BUCKETS_ARTIFACT|OCI reference to buckets artifact (matrix mode only)|
|BUCKET_INDICES|Array of bucket indices for matrix expansion (matrix mode only)|
|TOTAL_IMAGES|Total number of unique images (matrix mode only)|


## Additional info
