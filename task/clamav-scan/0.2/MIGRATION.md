# Migration from 0.1 to 0.2

Version 0.2:

On this version the sidecar is removed from the task and required tools (jq, oc ..) were added to the Clamav BD container image
this should fix the problem of timing out when task is scanning the database and improve the performance.

## Action from users

Renovate bot PR will be created with warning icon for a clamav-scan which is expected, no actions from users are required.
