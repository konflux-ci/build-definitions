# Migration from 0.2 to 0.3

- The required `IMAGE_DIGEST` parameter has been added back.

## Action from users

- All resources used task `sast-coverity-check` should be directed to use new `0.3` version.
- The `IMAGE_DIGEST` parameter definition is required to be added for this task in the build pipeline.

