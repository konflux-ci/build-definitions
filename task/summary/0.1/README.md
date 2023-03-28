# summary task

Summary Pipeline Task. Prints PipelineRun information, removes image repository secret used by the PipelineRun.

## Parameters
|name|description|default value|required|
|---|---|---|---|
|pipelinerun-name|pipeline-run to annotate||true|
|git-url|Git URL||true|
|image-url|Image URL||true|
|build-task-status|State of build task in pipelineRun|Succeeded|false|

