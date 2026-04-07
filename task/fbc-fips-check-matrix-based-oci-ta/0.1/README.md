# fbc-fips-check-matrix-based-oci-ta task

This is the matrix version of `fbc-fips-check-oci-ta`. Both tasks have the same FIPS compliance checking functionality, but this version supports parallel processing via Tekton matrix expansion.

## Why use the matrix version?

The standalone `fbc-fips-check-oci-ta` processes all images sequentially in a single task, which can be slow for FBC fragments with many related images. The matrix version addresses this by:

- **Faster execution**: Distributes images across multiple parallel tasks, significantly reducing total processing time
- **Better scalability**: Handles large FBC fragments with dozens or hundreds of related images more efficiently
- **Load balancing**: Uses size-based distribution to ensure balanced workloads across parallel tasks
- **Resource efficiency**: Each parallel task uses fewer resources, avoiding memory pressure from processing all images in one task

**Choose the right task:**
- `fbc-fips-check-oci-ta` - Standalone mode, single task, simpler setup, suitable for small FBC fragments
- `fbc-fips-check-matrix-based-oci-ta` - Matrix mode, parallel processing, recommended for large FBC fragments with many related images

This task is designed to work with `fbc-fips-prepare-oci-ta` using matrix expansion on the `BUCKET_INDEX` parameter.
The prepare task extracts relatedImages from unreleased operator bundles, deduplicates them, and distributes them across buckets for parallel processing.

## Usage

This task requires pairing with `fbc-fips-prepare-oci-ta`:

1. **fbc-fips-prepare-oci-ta**: Extracts unique related images from FBC fragment and creates bucket artifacts
2. **fbc-fips-check-matrix-based-oci-ta**: Processes one bucket of images (run with matrix expansion)

Example pipeline snippet:
```yaml
- name: fbc-fips-prepare
  taskRef:
    name: fbc-fips-prepare-oci-ta
  params:
    - name: NUM_BUCKETS
      value: "3"
    # ... other params

- name: fbc-fips-check
  taskRef:
    name: fbc-fips-check-matrix-based-oci-ta
  matrix:
    params:
      - name: BUCKET_INDEX
        value: $(tasks.fbc-fips-prepare.results.BUCKET_INDICES[*])
  params:
    - name: BUCKETS_ARTIFACT
      value: $(tasks.fbc-fips-prepare.results.BUCKETS_ARTIFACT)
```

## Parameters
|name|description|default value|required|
|---|---|---|---|
|BUCKETS_ARTIFACT|OCI reference to buckets artifact from fbc-fips-prepare-oci-ta||true|
|BUCKET_INDEX|Which bucket to process (0, 1, 2, ...)||true|
|MAX_PARALLEL|Maximum number of images to process in parallel within this bucket|2|false|

## Results
|name|description|
|---|---|
|IMAGES_PROCESSED|Images processed in the task|
|TEST_OUTPUT|Tekton task test output|

## Additional info
### Parallel Processing
The MAX_PARALLEL parameter controls how many related images are scanned concurrently within each bucket.
The default value is "2", which is lower than the standalone task since multiple buckets run in parallel.

### Error Propagation
If the prepare task encounters an error (e.g., cannot render FBC fragment), the error is propagated through the bucket artifact and reported in the TEST_OUTPUT result of this task.
