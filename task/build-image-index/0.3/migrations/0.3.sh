#!/usr/bin/env bash

set -e
declare -r pipeline_file=${1:?missing pipeline file}

tasks_names=()
tasks_selector="(.spec.tasks[], .spec.pipelineSpec.tasks[])"

for task_refname in "build-image-index" "build-image-index-min"; do
    task_selector="${tasks_selector} | select(.taskRef.params[] | (.name == \"name\" and .value == \"${task_refname}\"))"
    if yq -e "$task_selector" "$pipeline_file" >/dev/null 2>&1; then
        tasks_found="$(yq -e "${task_selector} | .name" "${pipeline_file}")"
        readarray -t -O ${#tasks_names[@]} tasks_names <<< "${tasks_found}"
    fi
done

if [ ${#tasks_names[@]} -eq 0 ]; then
    echo "No build-image-index tasks found"
    exit 0
fi

for task_name in "${tasks_names[@]}"; do
    pmt modify -f "$pipeline_file" task "$task_name" remove-param COMMIT_SHA
    pmt modify -f "$pipeline_file" task "$task_name" remove-param IMAGE_EXPIRES_AFTER
done
