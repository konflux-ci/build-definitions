# Migration from 0.2 to 0.3

Version 0.2:

- The `image-digest` parameter is now required and does not have a default value (previously `""`). Task runs without this parameter will fail.

## Action from users

- The `image-digest` parameter is required to be added to this task in the build pipeline.
