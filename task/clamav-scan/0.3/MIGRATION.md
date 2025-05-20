# Migration from 0.2 to 0.3

Version 0.3:

On this version clamscan is replaced by clamdscan which can scan an image in parallel (8 threads by default).
Besides that, if the pipeline task uses a matrix configuration for the task, each arch will create a separate TaskRun, running in parallel.

## Action from users

Renovate bot PR will be created with warning icon for a clamav-scan which is expected, no actions from users are required.
