# Migration from 0.1 to 0.2

Version 0.2:

This version introduces matrix mode for parallel processing of FIPS checks. It requires pairing with `fbc-fips-prepare-oci-ta` task.

**Note**: v0.1 and v0.2 serve different use cases:
- **v0.1**: Standalone mode (single task, simple setup)
- **v0.2**: Matrix mode (parallel processing, better performance for large image sets)

## When to migrate

Migrate to v0.2 if:
- Your FBC fragments contain many related images (10+)
- Build times are important and you want parallel processing
- You have sufficient cluster resources for parallel TaskRuns

Stay on v0.1 if:
- Your FBC fragments have few images
- You prefer simple, single-task setup
- Resource constraints limit parallel execution

## Migration steps

Replace the single `fbc-fips-check-oci-ta` task with two tasks:

### Before (v0.1)
```yaml
- name: fbc-fips-check-oci-ta
  taskRef:
    resolver: git
    params:
      - name: url
        value: https://github.com/konflux-ci/build-definitions
      - name: revision
        value: main
      - name: pathInRepo
        value: task/fbc-fips-check-oci-ta/0.1/fbc-fips-check-oci-ta.yaml
  params:
    - name: SOURCE_ARTIFACT
      value: $(tasks.clone-repository.results.SOURCE_ARTIFACT)
    - name: image-digest
      value: $(tasks.build-container.results.IMAGE_DIGEST)
    - name: image-url
      value: $(tasks.build-container.results.IMAGE_URL)
```

### After (v0.2)
```yaml
# Step 1: Prepare images and split into buckets
- name: fbc-fips-prepare-oci-ta
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
- name: fbc-fips-check-oci-ta
  runAfter:
    - fbc-fips-prepare-oci-ta
  matrix:
    params:
      - name: BUCKET_INDEX
        value: $(tasks.fbc-fips-prepare-oci-ta.results.BUCKET_INDICES[*])
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
      value: $(tasks.fbc-fips-prepare-oci-ta.results.BUCKETS_ARTIFACT)
    - name: MAX_PARALLEL
      value: "2"
```

## Automated migration

The migration script `migrations/0.2.sh` can automatically update build pipeline definition files when MintMaker runs [pipeline-migration-tool](https://github.com/konflux-ci/pipeline-migration-tool).
