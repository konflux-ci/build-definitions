#!/usr/bin/env bash

set -euo pipefail
declare -r pipeline_file=${1:?missing pipeline file}

tasks_names=()
tasks_selector="(.spec.tasks[], .spec.pipelineSpec.tasks[])"

for task_refname in "git-clone" "git-clone-oci-ta" "git-clone-oci-ta-min" "pnc-prebuild-git-clone-oci-ta"; do
    task_selector="${tasks_selector} | select(.taskRef.params[] | (.name == \"name\" and .value == \"${task_refname}\"))"
    if yq -e "$task_selector" "$pipeline_file" >/dev/null 2>&1; then
        tasks_found="$(yq -e "${task_selector} | .name" "${pipeline_file}")"
        readarray -t -O ${#tasks_names[@]} tasks_names <<< "${tasks_found}"
    fi
done

if [ ${#tasks_names[@]} -eq 0 ]; then
    echo "No git-clone tasks found"
    exit 0
fi

for task_name in "${tasks_names[@]}"; do
    task_name_selector="${tasks_selector} | select(.name == \"${task_name}\")"
    verbose_val=$(yq -e "${task_name_selector} | .params[] | select(.name == \"verbose\") | .value" "$pipeline_file" 2>/dev/null) || true

    pmt modify -f "$pipeline_file" task "$task_name" remove-param gitInitImage
    pmt modify -f "$pipeline_file" task "$task_name" remove-param verbose
    pmt modify -f "$pipeline_file" task "$task_name" remove-param userHome
    if [ "${verbose_val}" = "true" ]; then
        pmt modify -f "$pipeline_file" task "$task_name" add-param logLevel "debug"
    fi
done
