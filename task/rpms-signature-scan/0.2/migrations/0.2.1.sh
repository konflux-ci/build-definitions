#!/usr/bin/env bash

set -euo pipefail

# Created for task: rpms-signature-scan@0.2.1
# Creation time: 2025-12-01T00:00:00Z

declare -r pipeline_file=${1:?missing pipeline file}

# Combined selector for tasks in both Pipeline and PipelineRun
# Includes regular tasks and finally tasks in both Pipeline and PipelineRun resources
TASKS_SELECTOR="(.spec.tasks[]?, .spec.pipelineSpec.tasks[]?, .spec.finally[]?, .spec.pipelineSpec.finally[]?)"

# Check if rpms-signature-scan task exists with konflux-vanguard bundle
# If no tasks need migration, exit 0
if ! yq -e "${TASKS_SELECTOR} | select(.taskRef.params[]? | (.name == \"name\" and .value == \"rpms-signature-scan\")) | select(.taskRef.params[]? | (.name == \"bundle\" and (.value | contains(\"konflux-vanguard\"))))" "$pipeline_file" >/dev/null 2>&1; then
    echo "Pipeline does not require rpms-signature-scan bundle migration, skipping"
    exit 0
fi

# Find tasks by name and update bundle references
# Use a single yq command to find all taskRefs that need updating (matches name AND old bundle)
# Returns JSON objects with {path: <taskRef path>, content: <taskRef object>}
yq -o json '
    ('"$TASKS_SELECTOR"')
    | select(.taskRef.params[]? | (.name == "name" and .value == "rpms-signature-scan"))
    | select(.taskRef.params[]? | (.name == "bundle" and (.value | contains("konflux-vanguard"))))
    | {"path": (path | . + ["taskRef"]), "content": .taskRef, "task_name": .name}
' "$pipeline_file" | \
jq -c '.' | while read -r task_info; do
    if [ -n "$task_info" ] && [ "$task_info" != "null" ]; then
        # Extract path and task name
        pmt_path=$(echo "$task_info" | jq -c '.path')
        task_name=$(echo "$task_info" | jq -r '.task_name // "unknown"')

        # Update the bundle value within the extracted content
        # Only replace konflux-vanguard with tekton-catalog when it's a complete path segment
        updated_content=$(echo "$task_info" | jq -c '
            .content
            | (.params[]? | select(.name == "bundle") | .value) |=
              (gsub("/konflux-vanguard(?=[/@:]|$)"; "/tekton-catalog"))
        ')

        echo "Updating bundle reference in task '$task_name' from konflux-vanguard to tekton-catalog"

        # Replace the entire taskRef section instead of only update the bundle value
        # This is a workaround for https://issues.redhat.com/browse/STONEBLD-4024
        pmt modify -f "$pipeline_file" generic replace "$pmt_path" "$updated_content"
    fi
done
