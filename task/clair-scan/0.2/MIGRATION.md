# Migration from 0.1 to 0.2

The parameter `docker-auth` used by `clair-scan` task was removed.

## Action from users

Update files in Pull-Request created by RHTAP bot:
- Search for the task named `clair-scan`
- Remove the `docker-auth` parameter from the params section
