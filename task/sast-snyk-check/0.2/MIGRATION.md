# Migration from 0.1 to 0.2

Scanned dir `SOURCE_CODE_DIR`=$(workspaces.workspace.path)/source changed to `SOURCE_CODE_DIR`=$(workspaces.workspace.path)
Added `--max-depth`=1 option, so snyk is now scanning both source code and dependencies within workspace.
