#!/usr/bin/env bash

set -euo pipefail

# Created for task: init@0.2.5
# Creation time: 2025-12-04T00:00:00Z

declare -r pipeline_file=${1:?missing pipeline file}

# 1. Check for init task
# If init task does not exist, exit 0
if ! yq -e '(.spec.tasks[], .spec.pipelineSpec.tasks[]) | select(.name == "init")' "$pipeline_file" >/dev/null 2>&1; then
    echo "Pipeline does not use init task, skipping migration"
    exit 0
fi

# 2. Pipeline Parameter (enable-cache-proxy)
# Add enable-cache-proxy parameter if it doesn't exist
# pmt modify generic insert is not idempotent, we need to check if it exists first
if ! yq -e '(.spec.params[], .spec.pipelineSpec.params[]) | select(.name == "enable-cache-proxy")' "$pipeline_file" >/dev/null 2>&1; then
    echo "Adding enable-cache-proxy pipeline param"

    # Determine paths based on whether it is a Pipeline or PipelineRun
    if yq -e '.spec.pipelineSpec' "$pipeline_file" >/dev/null 2>&1; then
        # PipelineRun with embedded spec
        PARAMS_PATH=".spec.pipelineSpec.params"
        PMT_PARAMS_PATH='["spec", "pipelineSpec", "params"]'
        PMT_SPEC_PATH='["spec", "pipelineSpec"]'
    else
        # Pipeline
        PARAMS_PATH=".spec.params"
        PMT_PARAMS_PATH='["spec", "params"]'
        PMT_SPEC_PATH='["spec"]'
    fi

    # Check if params exists
    if yq -e "$PARAMS_PATH" "$pipeline_file" >/dev/null 2>&1; then
        # params exists, append to it
        pmt modify -f "$pipeline_file" generic insert \
            "$PMT_PARAMS_PATH" \
            '{"name": "enable-cache-proxy", "default": "false", "description": "Enable cache proxy configuration", "type": "string"}'
    else
        # params does not exist, create it with the param
        pmt modify -f "$pipeline_file" generic insert \
            "$PMT_SPEC_PATH" \
            '{"params": [{"name": "enable-cache-proxy", "default": "false", "description": "Enable cache proxy configuration", "type": "string"}]}'
    fi
else
    echo "enable-cache-proxy pipeline parameter already exists, checking tasks..."
fi

# 3. Init Task Parameter (enable-cache-proxy)
# Add enable-cache-proxy parameter to init task if not present (pmt modify task add-param is idempotent)
echo "Ensuring enable-cache-proxy parameter exists in init task"
pmt modify -f "$pipeline_file" task "init" add-param enable-cache-proxy "\$(params.enable-cache-proxy)"


# 4. Buildah Task Parameters (HTTP_PROXY, NO_PROXY)
# List of buildah task variants to look for
buildah_task_refs=( \
  "buildah" "buildah-oci-ta" \
  "buildah-remote" "buildah-remote-oci-ta" \
  "buildah-min" \
)

# Combined selector for tasks in both Pipeline and PipelineRun
TASKS_SELECTOR="(.spec.tasks[], .spec.pipelineSpec.tasks[])"

# Find all task names that use buildah variants
buildah_task_names=()
for task_ref in "${buildah_task_refs[@]}"; do
    # We handle multiple tasks using the same taskRef
    TASK_FILTER="${TASKS_SELECTOR} | select(.taskRef.name == \"${task_ref}\" or (.taskRef.params // [] | map(select(.name == \"name\" and .value == \"${task_ref}\")) | length > 0))"

    if yq -e "$TASK_FILTER" "$pipeline_file" >/dev/null 2>&1; then
        tasks_found=$(yq -r "$TASK_FILTER | .name" "$pipeline_file")
        readarray -t -O "${#buildah_task_names[@]}" buildah_task_names <<< "$tasks_found"
    fi
done

if [ ${#buildah_task_names[@]} -gt 0 ]; then
    for task_name in "${buildah_task_names[@]}"; do
        echo "Processing buildah task: $task_name"

        echo "  Ensuring HTTP_PROXY parameter exists for task $task_name"
        pmt modify -f "$pipeline_file" task "$task_name" add-param HTTP_PROXY "\$(tasks.init.results.http-proxy)"

        echo "  Ensuring NO_PROXY parameter exists for task $task_name"
        pmt modify -f "$pipeline_file" task "$task_name" add-param NO_PROXY "\$(tasks.init.results.no-proxy)"
    done
else
    echo "No buildah tasks found in pipeline"
fi
