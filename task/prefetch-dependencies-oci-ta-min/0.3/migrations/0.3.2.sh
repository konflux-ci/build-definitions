#!/usr/bin/env bash

set -euo pipefail

# Created for task: prefetch-dependencies-oci-ta-min@0.3.1
# Creation time: 2026-04-09T17:09:19+00:00

declare -r pipeline_file=${1:?missing pipeline file}

# 1. Find all prefetch-dependencies tasks in the pipeline
task_names=()
tasks_selector="(.spec.tasks[], .spec.pipelineSpec.tasks[])"

for task_refname in "prefetch-dependencies" "prefetch-dependencies-oci-ta" "prefetch-dependencies-oci-ta-min"; do
    task_selector="${tasks_selector} | select(.taskRef.params[] | (.name == \"name\" and .value == \"${task_refname}\"))"
    if yq -e "$task_selector" "$pipeline_file" >/dev/null; then
        tasks_found="$(yq -e "${task_selector} | .name" "${pipeline_file}")"
        readarray -t -O ${#task_names[@]} task_names <<< "${tasks_found}"
    fi
done

if [ ${#task_names[@]} -eq 0 ]; then
    echo "Pipeline does not use prefetch-dependencies task, skipping migration"
    exit 0
fi

# 2. Add enable-package-registry-proxy to the pipeline's top-level params
# pmt generic insert is not idempotent, so check first
if yq -e '(.spec.params[], .spec.pipelineSpec.params[]) | select(.name == "enable-package-registry-proxy")' "$pipeline_file" >/dev/null 2>&1; then
    echo "enable-package-registry-proxy pipeline parameter already exists"
else
    echo "Adding enable-package-registry-proxy pipeline param"

    # Params live at different paths in Pipeline vs PipelineRun (embedded spec)
    if yq -e '.spec.pipelineSpec' "$pipeline_file" >/dev/null 2>&1; then
        params_path=".spec.pipelineSpec.params"
        pmt_params_path='["spec", "pipelineSpec", "params"]'
        pmt_spec_path='["spec", "pipelineSpec"]'
    else
        params_path=".spec.params"
        pmt_params_path='["spec", "params"]'
        pmt_spec_path='["spec"]'
    fi

    param_json='{"name": "enable-package-registry-proxy", "default": "true", "description": "Use the package registry proxy when prefetching dependencies", "type": "string"}'

    if yq -e "$params_path" "$pipeline_file" >/dev/null 2>&1; then
        pmt modify -f "$pipeline_file" generic insert "$pmt_params_path" "$param_json"
    else
        pmt modify -f "$pipeline_file" generic insert "$pmt_spec_path" "{\"params\": [$param_json]}"
    fi
fi

# 3. Pass the pipeline param to each prefetch-dependencies task (add-param is idempotent)
for task_name in "${task_names[@]}"; do
    echo "Ensuring enable-package-registry-proxy parameter exists for task $task_name"
    pmt modify -f "$pipeline_file" task "$task_name" add-param enable-package-registry-proxy "\$(params.enable-package-registry-proxy)"
done
