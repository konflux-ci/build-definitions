# Migration from 0.1 to 0.2

- The workspace has been renamed to `source` to make the interface compatible
  with the `build-container` task.

- The unused `IMAGE_DIGEST` parameter has been removed.

## Action from users

- The workspace for this task in the build pipeline should be renamed to `source`.
- The parameter definition can be removed for this task in the build pipeline.
