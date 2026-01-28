# fbc-fips-check-worker-oci-ta task

The fbc-fips-check-worker task processes images from one bucket using the fips-operator-check-step-action to verify FIPS compliance of operator bundle relatedImages. This task is designed to work with Tekton matrix expansion, enabling parallel processing of multiple buckets concurrently.

This task is the second step in a multi-bucket FIPS checking pipeline. It retrieves bucket files created by the fbc-fips-prepare-oci-ta task from a trusted artifact, prepares the images for processing, and runs FIPS compliance checks using the fips-operator-check-step-action StepAction.

The task uses the check-payload tool to scan each image in the bucket. It processes images in parallel within the bucket (controlled by MAX_PARALLEL parameter) and returns aggregated test results including success, failure, warning, and error counts. Results are formatted as JSON test output compatible with Konflux test reporting.

## Parameters
|name|description|default value|required|
|---|---|---|---|
|BUCKETS_ARTIFACT|OCI reference to buckets artifact created by fbc-fips-prepare-oci-ta||true|
|BUCKET_INDEX|Which bucket to process (0, 1, 2, ...). Used with matrix expansion||true|
|MAX_PARALLEL|Maximum number of images to process in parallel within this bucket|2|false|

## Results
|name|description|
|---|---|
|TEST_OUTPUT|Tekton task test output in JSON format with result, successes, failures, warnings counts|


## Additional info

### Usage Example
This task should be used together with fbc-fips-prepare-oci-ta in a pipeline with matrix expansion. Here's how to connect both tasks:

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

**How it works**:
1. The `prepare` task returns BUCKET_INDICES (e.g., ["0","1","2"])
2. Matrix expansion creates 3 parallel `check-worker` TaskRuns, one per bucket
3. Each TaskRun processes its assigned bucket and returns TEST_OUTPUT with results

### Parallel Processing
The MAX_PARALLEL parameter controls how many images within a single bucket are scanned concurrently. The default value is "2", but this can be adjusted based on your resource availability:
- **Lower values (1-2)**: More conservative on memory/CPU, suitable for resource-constrained environments
- **Higher values (4-8)**: Faster processing if sufficient resources are available

Each image scan requires converting the image to OCI format, unpacking it, and running check-payload, which are memory-intensive operations. Adjust MAX_PARALLEL based on the memory limits assigned to the task.

### Test Output Format
The TEST_OUTPUT result contains aggregated results from all images in the bucket:
- **result**: Overall status (SUCCESS, WARNING, FAILURE, or ERROR)
- **successes**: Number of images that passed FIPS compliance
- **failures**: Number of images that failed FIPS compliance
- **warnings**: Number of images with FIPS compliance warnings
- **errors**: Number of images that could not be scanned (e.g., inaccessible, missing labels)
- **note**: Human-readable message about the result

This output can be aggregated across all bucket TaskRuns to produce a final FIPS compliance report.
