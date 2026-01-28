# fbc-fips-check-oci-ta task (v0.2)

The fbc-fips-check-oci-ta v0.2 task processes images from one bucket using the fips-operator-check-step-action to verify FIPS compliance of operator bundle relatedImages. This task is designed to work with Tekton matrix expansion for parallel processing.

**For standalone mode (single task), use [v0.1](../0.1/) instead.**

## Version Comparison

| Version | Mode | Use Case |
|---------|------|----------|
| v0.1 | Standalone | Simple, single-task FIPS check |
| v0.2 | Matrix | Parallel processing with `fbc-fips-prepare-oci-ta` |

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
|TEST_OUTPUT|Tekton task test output in JSON format with result, successes, failures, warnings counts|

## Usage

This task must be used together with `fbc-fips-prepare-oci-ta` in a pipeline with matrix expansion:

```yaml
apiVersion: tekton.dev/v1
kind: Pipeline
metadata:
  name: fbc-builder-parallel
spec:
  params:
    - name: output-image
      type: string
  tasks:
    # ... other tasks (clone-repository, build-container, etc.) ...

    # Step 1: Extract images and split into buckets
    - name: fbc-fips-prepare
      runAfter:
        - build-container
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
            value: task/fbc-fips-check-oci-ta/0.2/fbc-fips-check-oci-ta.yaml
      params:
        - name: BUCKETS_ARTIFACT
          value: $(tasks.fbc-fips-prepare.results.BUCKETS_ARTIFACT)
        - name: MAX_PARALLEL
          value: "2"
```

## How It Works

```
┌─────────────────────┐
│  fbc-fips-prepare   │
│  - Extract images   │
│  - Split into N     │
│    buckets          │
└──────────┬──────────┘
           │
           │ BUCKET_INDICES: ["0","1","2"]
           │ BUCKETS_ARTIFACT: oci://...
           ▼
    ┌──────┴──────┐
    │   Matrix    │
    │  Expansion  │
    └──────┬──────┘
           │
     ┌─────┼─────┐
     ▼     ▼     ▼
┌────────┐ ┌────────┐ ┌────────┐
│Bucket 0│ │Bucket 1│ │Bucket 2│
│ check  │ │ check  │ │ check  │
└────────┘ └────────┘ └────────┘
     │         │         │
     └─────────┴─────────┘
               │
               ▼
        TEST_OUTPUT x 3
```

1. `fbc-fips-prepare` extracts images, deduplicates them, and distributes across buckets with load balancing
2. It returns `BUCKET_INDICES` (e.g., `["0","1","2"]`) for matrix expansion
3. Tekton creates parallel `fbc-fips-check` TaskRuns, one per bucket
4. Each TaskRun processes its assigned bucket and returns `TEST_OUTPUT`

## Parallel Processing

The `MAX_PARALLEL` parameter controls how many images within a single bucket are scanned concurrently:
- **Lower values (1-2)**: More conservative on memory/CPU
- **Higher values (4-8)**: Faster processing if sufficient resources

## Test Output Format

The `TEST_OUTPUT` result contains:
- **result**: Overall status (SUCCESS, WARNING, FAILURE, or ERROR)
- **successes**: Number of images that passed FIPS compliance
- **failures**: Number of images that failed FIPS compliance
- **warnings**: Number of images with warnings
- **note**: Human-readable message
