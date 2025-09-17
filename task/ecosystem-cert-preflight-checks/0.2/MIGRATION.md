# Migration from 0.1 to 0.2

New optional parameters `artifact-type` can be explicitly set to control the
application of ecosystem checks on your image.

## Action from users

### Parameters

No **required** action for users.

Optionally, users may choose to explicitly set `artifact-type` to a predefined
value if they wish to explicitly control the type of artifact (e.g. application
image "application", or operator bundle image "operatorbundle"). Otherwise, this
is introspected.

# Migration from 0.2 to 0.2.1

Version 0.2.1:

matrix can be configured for the task to improve performance for multi-arch build.

Changes:
For multi-arch builds, `matrix` is added to the build pipeline definition file.

## Action from users
Renovate bot PR will be created with warning icon for a ecosystem-cert-preflight-checks
which is expected, no actions from users are required for the task.

For multi-arch build, `matrix` will be added to build pipeline definition file
automatically by script migrations/0.2.1.sh when MintMaker runs
[pipeline-migration-tool](https://github.com/konflux-ci/pipeline-migration-tool).
