# Migration from 0.3 to 0.4

Version 0.4:

- The `image-digest` parameter has been introduced back, to be used in ORAS uploading.
- The `image-url` default value was removed, thus it become required  
## Action from users
- The `image-digest` parameter definition can optionally be added for this task in the build pipeline.
- User must provide the `image-url` parameter's value.