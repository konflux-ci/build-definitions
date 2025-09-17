# Migration from 0.2 to 0.3

- Both `image-digest` and `image-url` parameters are now required and do not have default values
  (previously `""`). Task runs without passing image digest and URL will fail.

## Action from users

- Both `image-digest` and `image-url` parameters are required to be added to this task in the build pipeline.
