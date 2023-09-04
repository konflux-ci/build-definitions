# Migration from 0.2 to 0.3

Workspace used by the `deprecated-image-check` is removed. This is not required as it doesn't need any PVCs. 

## Action from users

Update files in Pull-Request created by RHTAP bot:
- Search for the task named `deprecated-base-image-check`
- Remove the workspaces section from [deprecated-image-check.yaml](https://github.com/redhat-appstudio/build-definitions/blob/main/task/deprecated-image-check/0.2/deprecated-image-check.yaml)
- Replace `$(workspaces.test-ws.path)` with `/tekton/home`
