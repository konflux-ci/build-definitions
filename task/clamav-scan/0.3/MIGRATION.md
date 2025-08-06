# Migration from 0.2 to 0.3

Version 0.3:

On this version clamscan is replaced by clamdscan which can scan an image in parallel (8 threads by default).
Besides that, if the pipelinerun uses a matrix configuration for the task, each arch will create a separate TaskRun, running in parallel.

Changes:
- The `image-arch` parameter definition is added and the defaul value is "".
- The `clamd-max-threads` parameter definition is added and the default is 8.
- For multi-architecture builds, `matrix` is added to the build pipeline definition file.

## Action from users

Renovate bot PR will be created with warning icon for a clamav-scan which is expected, no actions from users are required for the task.

Important:
Do not enable matrix in PipelineRuns until https://issues.redhat.com/browse/KONFLUX-9576 is resolved.
