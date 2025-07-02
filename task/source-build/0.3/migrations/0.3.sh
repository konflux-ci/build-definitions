#!/usr/bin/env bash

set -euo pipefail

# Created for task: source-build@0.3
# Creation time: 2025-06-13T09:02:59+00:00

declare -r pipeline_file=${1:?missing pipeline file}

task_selector() {
    printf ".spec.tasks[] | select(.name == \"%s\")" "$1"
}

# Check if given task exists
# Args: task_name
task_exists() {
    local -r task_name=$1
    yq -e "$(task_selector "$task_name")" "$pipeline_file" >/dev/null 2>&1
}

# Add a task parameter
# Args: task_name param_name param_value
add_task_param() {
    local task_name=$1 param_name=$2 param_value=$3
    local param="{\"name\": \"${param_name}\", \"value\": \"${param_value}\"}"
    yq -e -i "($(task_selector "$task_name") | .params) += [$param]" "$pipeline_file"
}

get_task_param_value() {
    local task_name=$1 param_name=$2
    yq -e "$(task_selector "$task_name") | .params[] | select(.name == \"${param_name}\") | .value" \
       "$pipeline_file" 2>/dev/null
}

update_task_param_value() {
    local task_name=$1 param_name=$2 param_value=$3
    yq -e -i "($(task_selector "$task_name") | .params[] | select(.name == \"${param_name}\") | .value) |= \"$param_value\"" \
       "$pipeline_file" 2>/dev/null
}


build_task_name=

if task_exists build-oci-artifact; then
    build_task_name=build-oci-artifact
elif task_exists build-image-index; then
    build_task_name=build-image-index
elif task_exists build-container; then
    build_task_name=build-container
else
    echo "None of build tasks build-oci-artifact, build-image-index and build-container is found."
    exit 0
fi

declare -r params="
BINARY_IMAGE \$(tasks.${build_task_name}.results.IMAGE_URL)
BINARY_IMAGE_DIGEST \$(tasks.${build_task_name}.results.IMAGE_DIGEST)
"

declare -r TARGET_TASK=build-source-image

echo "Applying migration to pipeline ${pipeline_file}"

# Set value to task parameter. Value of existing parameter is replaced. If the
# parameter is not present yet, append it to the parameters.
# Args: task_name param_name param_value
set_task_param_value() {
    local task_name=$1 param_name=$2 param_value=$3
    if value=$(get_task_param_value "$task_name" "$param_name"); then
        if [[ $value == "$param_value" ]]; then
            echo "Task parameter $param_name with value $param_value exists already."
        else
            if ! update_task_param_value "$task_name" "$param_name" "$param_value"; then
                echo "Cannot update parameter $param_name with value $param_value for task $task_name"
            fi
        fi
    else
        echo "Adding parameter $param_name to task $task_name"
        if ! add_task_param "$task_name" "$param_name" "$param_value"; then
            echo "Failed to add parameter ${param_name}:${param_value} to task $task_name"
        fi
    fi
}

while read -r param_name param_value
do
    if [ -z "$param_name" ]; then
        continue
    fi
    set_task_param_value "$TARGET_TASK" "$param_name" "$param_value"
done <<<"$params"
