# reduce-snapshot-to-single-component task

This task is designed to reduce the Snapshot that is passed to the Enterprise Contract verify task. 

If activated via the SINGLE_COMPONENT parameter, then the Snapshot is filtered to only contain the Component which caused the Snapshot to be built.

The use case for this reduction is based on the desire to have components that are built to be quickly released
regardless of any other Components within the Snapshot and Application. 

## Parameters
| name              | description                                                                              | default value | required   |
|-------------------|------------------------------------------------------------------------------------------|---------------|------------|
| SNAPSHOT          | Snapshot to possibly reduce                                                              |               | true       |
| SINGLE_COMPONENT  | Reduce the Snapshot to only the component whose build caused the Snapshot to be created  | false         | false      |
| PIPELINERUN_ID    | Name of current PipelineRun.                                                             |               | true       |

## Results
| name          | description                                  |
|---------------|----------------------------------------------|
| SNAPSHOT_PATH | Location in workspace for Resulting Snapshot |
