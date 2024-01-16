# Migration from 0.1 to 0.2

The parameters `skip-optional`, `pipelinerun-name` and ` pipelinerun-uid` used by `init` task were removed.

## Action from users

Update files in Pull-Request created by RHTAP bot:
- Search for the task named `init`
- Remove the `skip-optional`, `pipelinerun-name` and ` pipelinerun-uid` parameters from the params section
