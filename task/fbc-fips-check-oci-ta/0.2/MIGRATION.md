# Migration from 0.1 to 0.2

Version 0.2 introduces dual-mode support via the `NUM_WORKERS` parameter, enabling both inline FIPS checking (backward compatible) and parallel matrix-based checking.

## What's New

- **`NUM_WORKERS` parameter**: Controls the execution mode
  - `NUM_WORKERS=1` (default): Inline mode - runs FIPS check directly in this task (same as 0.1)
  - `NUM_WORKERS>1`: Matrix mode - splits images into buckets for parallel processing with `fbc-fips-check-worker-oci-ta` tasks
- **New parameters for matrix mode**: `SIZE_FETCH_PARALLEL`, `ociStorage`, `ociArtifactExpiresAfter`
- **New results for matrix mode**: `BUCKETS_ARTIFACT`, `BUCKET_INDICES`, `TOTAL_IMAGES`

## Action from users

**No action required for most users.** The default behavior (`NUM_WORKERS=1`) is fully backward compatible with 0.1.

### Optional: Enable parallel processing

If you have many large images and want to speed up FIPS checking, you can enable matrix mode:

1. Set `NUM_WORKERS` to the desired number of parallel workers (e.g., `"4"`)
2. Add `ociStorage` parameter pointing to your OCI storage URL
3. Add `fbc-fips-check-worker-oci-ta` tasks with matrix expansion

Example pipeline configuration for matrix mode:

```yaml
# Prepare task - splits images into buckets
- name: fbc-fips-prepare
  params:
    - name: image-digest
      value: $(tasks.build-image-index.results.IMAGE_DIGEST)
    - name: image-url
      value: $(tasks.build-image-index.results.IMAGE_URL)
    - name: SOURCE_ARTIFACT
      value: $(tasks.clone-repository.results.SOURCE_ARTIFACT)
    - name: ociStorage
      value: $(params.output-image)
    - name: NUM_WORKERS
      value: "4"
  taskRef:
    resolver: bundles
    params:
      - name: bundle
        value: quay.io/konflux-ci/tekton-catalog/task-fbc-fips-check-oci-ta:0.2
      - name: name
        value: fbc-fips-check-oci-ta
      - name: kind
        value: Task

# Worker tasks - process buckets in parallel
- name: fbc-fips-check
  runAfter:
    - fbc-fips-prepare
  when:
    - input: "$(tasks.fbc-fips-prepare.results.TOTAL_IMAGES)"
      operator: notin
      values: ["0"]
  matrix:
    params:
      - name: BUCKET_INDEX
        value: $(tasks.fbc-fips-prepare.results.BUCKET_INDICES[*])
  taskRef:
    resolver: bundles
    params:
      - name: bundle
        value: quay.io/konflux-ci/tekton-catalog/task-fbc-fips-check-worker-oci-ta:0.1
      - name: name
        value: fbc-fips-check-worker-oci-ta
      - name: kind
        value: Task
  params:
    - name: BUCKETS_ARTIFACT
      value: $(tasks.fbc-fips-prepare.results.BUCKETS_ARTIFACT)
```
