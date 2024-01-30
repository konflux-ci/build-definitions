# Migration from 0.1 to 0.2

The parameter `DOCKER_AUTH` used by `inspect-image` task was removed.

## Action from users

Update files in Pull-Request created by RHTAP bot:
- Search for the task named `inspect-image`
- Remove the `DOCKER_AUTH` parameter from the params section
