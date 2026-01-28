# fbc-fips-prepare-oci-ta task

The fbc-fips-prepare task extracts relatedImages from all unreleased operator bundle images in an FBC fragment, deduplicates them, and distributes them across multiple buckets for parallel FIPS compliance checking.

This task is designed to work as the first step in a multi-bucket FIPS checking pipeline. It processes the FBC fragment to identify unreleased operator bundles (those not present in the Red Hat production Index Image `registry.redhat.io/redhat/redhat-operator-index`), extracts their relatedImages, and intelligently distributes them across buckets using size-based load balancing.

The task uses a greedy algorithm to fetch image sizes in parallel and assign larger images to different buckets, ensuring balanced workload distribution. This enables efficient parallel FIPS checking by processing different buckets concurrently using the fbc-fips-check-worker-oci-ta task.

In order to resolve unreleased image pullspecs, this task expects an ImageDigestMirrorSet file located at .tekton/images-mirror-set.yaml of your FBC fragment git repo. It should map unreleased registry.redhat.io pullspecs of relatedImages to their valid quay.io pullspecs. If the ImageDigestMirrorSet is not provided, the task will attempt to process the registry.redhat.io pullspecs as is and might fail.

## Parameters
|name|description|default value|required|
|---|---|---|---|
|SOURCE_ARTIFACT|The Trusted Artifact URI pointing to the artifact with the application source code||true|
|image-digest|Image digest to scan||true|
|image-url|Image URL||true|
|output-image|Base image URL for storing artifacts||true|
|NUM_BUCKETS|Number of buckets to create|2|false|
|SIZE_FETCH_PARALLEL|Number of parallel image size fetches for load balancing|5|false|

## Results
|name|description|
|---|---|
|BUCKETS_ARTIFACT|OCI reference to buckets artifact containing bucket files and metadata|
|BUCKET_INDICES|Array of bucket indices for matrix expansion (e.g., ["0","1","2"])|
|TOTAL_IMAGES|Total number of unique images extracted and distributed|


## Additional info

### Load Balancing Strategy
This task always uses load balancing to distribute images across buckets based on their actual sizes. The algorithm:
1. Fetches image sizes in parallel (controlled by SIZE_FETCH_PARALLEL)
2. Sorts images by size (largest first)
3. Uses a greedy algorithm to assign each image to the lightest bucket (bucket with smallest total size)

This ensures that buckets have roughly equal total workloads, preventing situations where one bucket has all the large images and takes significantly longer to process.

### Bucket Distribution
The NUM_BUCKETS parameter controls how many parallel processing buckets are created. Each bucket will be processed by a separate TaskRun using the fbc-fips-check-worker-oci-ta task, typically with matrix expansion. Increasing the number of buckets enables more parallelism but also creates more TaskRuns.

### Image Size Fetching
The SIZE_FETCH_PARALLEL parameter controls how many image size fetches run concurrently during load balancing. If image registries are accessible with good network connectivity, this can be increased to speed up the extraction phase. If many images fail to fetch sizes (due to network issues or authentication), they will be assigned size 0 and distributed to buckets normally.

### Usage Example
This task should be used together with fbc-fips-check-worker-oci-ta in a pipeline. Here's how to connect both tasks using matrix expansion:

```yaml
tasks:
  # Step 1: Extract images and split into buckets
  - name: prepare
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
        value: $(params.SOURCE_ARTIFACT)
      - name: image-digest
        value: $(params.image-digest)
      - name: image-url
        value: $(params.image-url)
      - name: output-image
        value: $(params.output-image)
      - name: NUM_BUCKETS
        value: "3"
      - name: SIZE_FETCH_PARALLEL
        value: "5"

  # Step 2: Process each bucket in parallel using matrix expansion
  - name: check-worker
    runAfter:
      - prepare
    matrix:
      params:
        - name: BUCKET_INDEX
          value: $(tasks.prepare.results.BUCKET_INDICES[*])
    taskRef:
      resolver: git
      params:
        - name: url
          value: https://github.com/konflux-ci/build-definitions
        - name: revision
          value: main
        - name: pathInRepo
          value: task/fbc-fips-check-worker-oci-ta/0.1/fbc-fips-check-worker-oci-ta.yaml
    params:
      - name: BUCKETS_ARTIFACT
        value: $(tasks.prepare.results.BUCKETS_ARTIFACT)
      - name: MAX_PARALLEL
        value: "2"
```

**How it works**: The prepare task creates buckets and returns BUCKET_INDICES (e.g., ["0","1","2"]). Matrix expansion then creates 3 parallel check-worker TaskRuns, one for each index, processing all buckets concurrently.
