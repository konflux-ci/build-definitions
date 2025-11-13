# Migration from 0.1 to 0.2

## What Changed

The `build-image-index` task now validates that all input platform images have the **same format** as the target index (specified by `BUILDAH_FORMAT`).
If a format mismatch is detected (e.g., a `docker` image is used to build an `oci` index), the task will `fail` with an error instead of trying to convert the formats.

## Action from users

If your task fails with:
`ERROR: Platform image <image ref> is in <oci|docker> format, but index will be <docker|oci>`

Ensure consistent format throughout pipeline:

```yaml
params:
  - name: buildah-format
    default: oci  # Must match across all tasks

tasks:
  - name: build-images
    params:
      - name: BUILDAH_FORMAT
        value: $(params.buildah-format)
  
  - name: build-image-index
    params:
      - name: BUILDAH_FORMAT
        value: $(params.buildah-format)  # Same value
```
