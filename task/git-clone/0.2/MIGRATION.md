# Migration from 0.1 to 0.2

The parameter `DOCKER_AUTH` used by `git-clone` task was removed.

## Action from users

Update files in Pull-Request created by RHTAP bot:
- Search for the task named `git-clone`
- Remove the `gitInitImage` parameter from the params section
