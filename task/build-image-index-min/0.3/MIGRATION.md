# Migration from 0.2 to 0.3

## What Changed

### Removed Parameters

The following parameters have been removed as they were not used by the task:

- **`COMMIT_SHA`**: This parameter was not used by the task implementation.
- **`IMAGE_EXPIRES_AFTER`**: This parameter was not used by the task implementation.

### Implementation Changes

- The task now uses `konflux-build-cli` for the build step instead of an inline bash
  implementation. This provides more robust error handling and simplified maintenance.
- When `ALWAYS_BUILD_INDEX` is `false` and multiple images are provided, the task now
  creates an image index instead of failing. The previous behavior (failing with an error)
  was not useful.
- Image reference validation is now stricter and will fail earlier for invalid formats.

## Action from Users

If you were passing `COMMIT_SHA` or `IMAGE_EXPIRES_AFTER` parameters, simply remove them from your pipeline configuration:

```yaml
- name: build-image-index
  params:
    - name: IMAGE
      value: $(params.output-image)
    - name: COMMIT_SHA # Remove this
      value: $(params.revision)
    - name: IMAGE_EXPIRES_AFTER # Remove this
      value: "5d" 
    - name: IMAGES
      value:
        - $(tasks.build-amd64.results.IMAGE_URL)@$(tasks.build-amd64.results.IMAGE_DIGEST)
        - $(tasks.build-arm64.results.IMAGE_URL)@$(tasks.build-arm64.results.IMAGE_DIGEST)
```
