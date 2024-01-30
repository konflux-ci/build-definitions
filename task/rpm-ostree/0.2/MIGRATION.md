# Migration from 0.1 to 0.2

The parameter `BUILDER-IMAGE` used by `rpm-ostree` task was removed.

## Action from users

Update files in Pull-Request created by RHTAP bot:
- Search for the task named `rpm-ostree`
- Remove the `BUILDER-IMAGE` parameter from the params section
