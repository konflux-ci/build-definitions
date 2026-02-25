# Migration from 0.2 to 0.3
The optional parameter `STEPS_IMAGE_STEP_NAMES` was added to the task.
When set, only the specified step images are replaced by `STEPS_IMAGE` instead of all steps.

## Action from users
No action required. The `STEPS_IMAGE_STEP_NAMES` parameter defaults to an empty string, preserving the existing behavior of replacing all step images.
