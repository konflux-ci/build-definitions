# wait-for-pipelinerun-image task

The `wait-for-pipelinerun-image` Task waits for the most recent Tekton PipelineRun matching a given label selector to finish, then emits the image URL and digest that the PipelineRun published in its results.

## Parameters
|name|description|default value|required|
|---|---|---|---|
|selector|Label selector used to locate the target PipelineRuns (for example, `tekton.dev/pipelineRun=my-build`).||true|
|wait-timeout|Maximum time to wait for the selected PipelineRun to report a completion time (for example, `20m` or `120s`).|20m|false|

## Results
|name|description|
|---|---|
|IMAGE_URL|Canonical image URL (typically registry/repository, without digest).|
|IMAGE_DIGEST|SHA256 digest of the image manifest.|

## Behavior

1. Lists PipelineRuns that match `selector`, sorted by creation timestamp.
2. Picks the newest PipelineRun and waits (up to `wait-timeout`) for it to finish.
3. Fails if the PipelineRun does not complete successfully or if the expected image results are missing.
4. Writes the discovered image URL and digest to the task results.

## Example

```yaml
apiVersion: tekton.dev/v1
kind: Pipeline
metadata:
  name: sample-wait-for-image
spec:
  tasks:
    - name: wait-for-image
      taskRef:
        name: wait-for-pipelinerun-image
      params:
        - name: selector
          value: build.appstudio.redhat.com/component=my-component
        - name: wait-timeout
          value: 30m
```