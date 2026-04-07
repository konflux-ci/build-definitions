# fbc-fips-prepare-oci-ta task

This is the prepare task for `fbc-fips-check-matrix-based-oci-ta`. Together they provide the same FIPS compliance checking functionality as the standalone `fbc-fips-check-oci-ta`, but with parallel processing support.

The task extracts relatedImages from all unreleased operator bundle images in an FBC fragment, deduplicates them, and distributes them across multiple buckets for parallel FIPS compliance checking.

It processes the FBC fragment to identify unreleased operator bundles (those not present in the Red Hat production Index Image `registry.redhat.io/redhat/redhat-operator-index`), extracts their relatedImages, and intelligently distributes them across buckets using size-based load balancing.

In order to resolve unreleased image pullspecs, this task expects an ImageDigestMirrorSet file located at .tekton/images-mirror-set.yaml of your FBC fragment git repo. It should map unreleased registry.redhat.io pullspecs of relatedImages to their valid quay.io pullspecs. If the ImageDigestMirrorSet is not provided, the task will attempt to process the registry.redhat.io pullspecs as is and might fail.

## Parameters
|name|description|default value|required|
|---|---|---|---|
|SOURCE_ARTIFACT|The Trusted Artifact URI pointing to the artifact with the application source code||true|
|image-digest|Image digest to scan||true|
|image-url|Image URL||true|
|image-mirror-set-path|Path to the image mirror set file.|.tekton/images-mirror-set.yaml|false|
|ociStorage|The OCI repository where the Trusted Artifacts are stored||true|
|NUM_BUCKETS|Number of buckets to create|1|false|
|SIZE_FETCH_PARALLEL|Number of parallel image size fetches for load balancing|5|false|

## Results
|name|description|
|---|---|
|BUCKETS_ARTIFACT|OCI reference to buckets artifact|
|BUCKET_INDICES|Array of bucket indices for matrix expansion|
|TOTAL_IMAGES|Total number of unique images|


## Additional info

### Load Balancing Strategy
This task always uses load balancing to distribute images across buckets based on their actual sizes. The algorithm:
1. Fetches image sizes in parallel (controlled by SIZE_FETCH_PARALLEL)
2. Sorts images by size (largest first)
3. Uses a greedy algorithm to assign each image to the lightest bucket (bucket with smallest total size)

This ensures that buckets have roughly equal total workloads, preventing situations where one bucket has all the large images and takes significantly longer to process.

### Bucket Distribution
The NUM_BUCKETS parameter controls how many parallel processing buckets are created. Each bucket will be processed by a separate TaskRun using the fbc-fips-check-matrix-based-oci-ta task, typically with matrix expansion. Increasing the number of buckets enables more parallelism but also creates more TaskRuns.

### Image Size Fetching
The SIZE_FETCH_PARALLEL parameter controls how many image size fetches run concurrently during load balancing. If image registries are accessible with good network connectivity, this can be increased to speed up the extraction phase. If many images fail to fetch sizes (due to network issues or authentication), they will be assigned size 0 and distributed to buckets normally.

### Usage Example
This task should be used together with fbc-fips-check-matrix-based-oci-ta in a pipeline. Here's how to connect both tasks using matrix expansion:

```yaml
tasks:
  # Step 1: Extract images and split into buckets
  - name: fbc-fips-prepare
    taskRef:
      resolver: git
      params:
        - name: url
          value: https://github.com/konflux-ci/build-definitions
        - name: revision
          value: main
        - name: pathInRepo
          value: task/fbc-fips-prepare-oci-ta/0.1/fbc-fips-prepare-oci-ta.yaml
    params:
      - name: SOURCE_ARTIFACT
        value: $(tasks.clone-repository.results.SOURCE_ARTIFACT)
      - name: image-digest
        value: $(tasks.build-container.results.IMAGE_DIGEST)
      - name: image-url
        value: $(tasks.build-container.results.IMAGE_URL)
      - name: ociStorage
        value: $(params.output-image)
      - name: NUM_BUCKETS
        value: "3"

  # Step 2: Process each bucket in parallel using matrix expansion
  - name: fbc-fips-check
    runAfter:
      - fbc-fips-prepare
    matrix:
      params:
        - name: BUCKET_INDEX
          value: $(tasks.fbc-fips-prepare.results.BUCKET_INDICES[*])
    taskRef:
      resolver: git
      params:
        - name: url
          value: https://github.com/konflux-ci/build-definitions
        - name: revision
          value: main
        - name: pathInRepo
          value: task/fbc-fips-check-matrix-based-oci-ta/0.1/fbc-fips-check-matrix-based-oci-ta.yaml
    params:
      - name: BUCKETS_ARTIFACT
        value: $(tasks.fbc-fips-prepare.results.BUCKETS_ARTIFACT)
      - name: MAX_PARALLEL
        value: "2"
```

**How it works**: The prepare task creates buckets and returns BUCKET_INDICES (e.g., ["0","1","2"]). Matrix expansion then creates 3 parallel fbc-fips-check TaskRuns, one for each index, processing all buckets concurrently.
