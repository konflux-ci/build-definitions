# Migration from 0.1 to 0.2

Version 0.2:

These changes originates from ProdSec requirements in order for sast snyk check to scan dependencies. See https://issues.redhat.com/browse/STONEINTG-1020 for more information.
Inherited from sast-snyk-check task,
Scanned dir `SOURCE_CODE_DIR`=$(workspaces.workspace.path)/source changed to `SOURCE_CODE_DIR`=$(workspaces.workspace.path)
Added `--max-depth`=1 option, so snyk is now scanning both source code and dependencies within workspace.

## Action from users

Renovate bot PR will be created with warning icon for a sast-snyk-check-oci-ta which is expected, no action from users are required.
