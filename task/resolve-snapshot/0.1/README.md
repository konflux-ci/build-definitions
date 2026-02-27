# resolve-snapshot task

Resolves the `SNAPSHOT` param to ApplicationSnapshot spec JSON. Accepts either the full spec JSON (pass-through) or the name of an ApplicationSnapshot resource in the pipeline run's namespace (fetched in-cluster). Used by the enterprise-contract pipeline so that Integration Test Scenarios can pass the snapshot by name via the annotation `test.appstudio.openshift.io/snapshot-param-as-name`.

When `SNAPSHOT` looks like JSON (starts with `{`), it is passed through unchanged. Otherwise it is treated as a snapshot name and the task fetches the ApplicationSnapshot from the cluster and outputs its `.spec` as JSON.

## Parameters
|name|description|default value|required|
|---|---|---|---|
|SNAPSHOT|Either the ApplicationSnapshot spec JSON string, or the name of an ApplicationSnapshot resource in the pipeline run's namespace.||true|

## Results
|name|description|
|---|---|
|SNAPSHOT_JSON|The ApplicationSnapshot spec as JSON (for use as IMAGES input to verify-enterprise-contract).|

## Additional info

### Snapshot by name (ITS)

When an IntegrationTestScenario has the annotation `test.appstudio.openshift.io/snapshot-param-as-name: "true"`, the integration-service sets the PipelineRun param `SNAPSHOT` to the **name** of the ApplicationSnapshot (e.g. `my-app-abc123`) instead of the full spec JSON. This task resolves that name to the spec so the enterprise-contract verify task receives valid input.

### Result size

Tekton task results have a size limit (e.g. 4KB in some setups). For very large snapshots (many components), pass the full spec JSON in `SNAPSHOT` rather than using snapshot-by-name if you hit that limit.
