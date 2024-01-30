# Migration from 0.1 to 0.2

The parameters `GIT_IMAGE` and `SCRIPT_IMAGE` used by `update-infra-deployments` task were removed.

## Action from users

Update files in Pull-Request created by RHTAP bot:
- Search for the task named `update-infra-deployments`
- Remove the `GIT_IMAGE` and `SCRIPT_IMAGE` parameters from the params section
