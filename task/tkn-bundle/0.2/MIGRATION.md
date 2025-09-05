# Migration from 0.1 to 0.2
The parameter `URL` was added to the task.
The parameter `REVISION` was added to the task.
The parameter `depth` is set to `100` in `clone-repository` task if `tkn-bundle-oci-ta` task or `tkn-bundle` task exists in pieline

## Action from users
Add the `URL` and `REVISION` parameters to the `tkn-bundle` task.
Set the `depth` to `100` in `clone-repository` task if `tkn-bundle` task exists in pipeline
