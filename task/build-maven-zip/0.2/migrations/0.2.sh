#!/usr/bin/env bash

set -euo pipefail

declare -r pipeline_file=${1:?missing pipeline file}

task_refname="build-maven-zip"
tasks_selector="(.spec.tasks[], .spec.pipelineSpec.tasks[])"
task_selector="${tasks_selector} | select(.taskRef.params[] | (.name == \"name\" and .value == \"${task_refname}\"))"

if ! yq -e "$task_selector" "$pipeline_file" >/dev/null 2>&1; then
    echo "No ${task_refname} task found. No changes needed."
    exit 0
fi

tasks_found="$(yq -e "${task_selector} | .name" "${pipeline_file}")"
readarray -t tasks_names <<< "${tasks_found}"

for task_name in "${tasks_names[@]}"; do
    # Rename IMAGE_EXPIRES_AFTER -> EXPIRES_AFTER (preserve value if set)
    expires_value=$(yq -e "${tasks_selector} | select(.name == \"${task_name}\").params[] | select(.name == \"IMAGE_EXPIRES_AFTER\").value" "$pipeline_file" 2>/dev/null || echo "")
    pmt modify -f "$pipeline_file" task "$task_name" remove-param IMAGE_EXPIRES_AFTER || true
    if [ -n "$expires_value" ]; then
        pmt modify -f "$pipeline_file" task "$task_name" add-param EXPIRES_AFTER "$expires_value"
    fi

    # Remove params that no longer exist
    pmt modify -f "$pipeline_file" task "$task_name" remove-param FILE_NAME || true
    pmt modify -f "$pipeline_file" task "$task_name" remove-param PREFETCH_ROOT || true
done