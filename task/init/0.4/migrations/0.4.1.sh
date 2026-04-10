#!/usr/bin/env bash

set -euo pipefail

# Created for task: init@0.4.1
# Creation time: 2026-04-26T18:28:34Z

declare -r pipeline_file=${1:?missing pipeline file}

# Get task names, a same task ref may be used multiple times, task names are unique but can be changed by users
tasks_names=()
tasks_selector="(.spec.tasks[], .spec.pipelineSpec.tasks[])"

# A migration script should find out tasks from a Pipeline/PipelineRun by the referenced real task name
for task_refname in "coverity-availability-check" "sast-coverity-check" "sast-coverity-check-oci-ta"; do
    task_selector="${tasks_selector} | select(.taskRef.params[] | (.name == \"name\" and .value == \"${task_refname}\"))"
    if yq -e "$task_selector" "$pipeline_file" >/dev/null; then
        tasks_found="$(yq -e "${task_selector} | .name" "${pipeline_file}")"
        readarray -t -O ${#tasks_names[@]} tasks_names <<< "${tasks_found}"  # multiple tasks names can be returned
    fi
done

if [ ${#tasks_names[@]} -eq 0 ]; then
    echo "No tasks found"
    exit 0
fi

for task_name in "${tasks_names[@]}"; do
   export task_name
   # shellcheck disable=SC2016
   if yq -e "${tasks_selector} | select (.name == strenv(task_name)) | path" "$pipeline_file" >/tmp/path.yaml 2>&1; then
    echo "Removing ${task_name}"
    pmt modify -f "$pipeline_file" generic remove "$(cat /tmp/path.yaml)"
   fi
done
