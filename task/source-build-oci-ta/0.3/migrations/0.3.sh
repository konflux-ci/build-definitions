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

# Check if given task parameter exists
# Args: taskname, param_name
task_param_exists() {
    local task_name=$1 param_name=$2
    yq -e "$(task_selector "$task_name") | .params[] | select(.name == \"$param_name\")" "$pipeline_file" >/dev/null 2>&1
}

# Add a task parameter
# Args: task_name param_name param_value
add_task_param() {
    local task_name=$1 param_name=$2 param_value=$3
    local param="{\"name\": \"${param_name}\", \"value\": \"${param_value}\"}"
    yq -e -i "($(task_selector "$task_name") | .params) += [$param]" "$pipeline_file"
}

# Remove parameter from a task
# Args: task_name param_name
remove_task_param() {
    local task_name=$1 param_name=$2
    yq -e -i "del(
        $(task_selector "$task_name") | .params[] | select(.name == \"$param_name\")
    )" "$pipeline_file"
}

declare build_task_name

if task_exists build-image-index
then
    build_task_name=build-image-index
elif task_exists build-container
then
    build_task_name=build-container
else
    echo "Neither build task build-image-index or build-container is found."
    exit 0
fi

declare -r params="
BINARY_IMAGE \$(tasks.${build_task_name}.results.IMAGE_URL)
BINARY_IMAGE_DIGEST \$(tasks.${build_task_name}.results.IMAGE_DIGEST)
"

declare -r TARGET_TASK=build-source-image

echo "Applying migration to pipeline ${pipeline_file}"

param_name=BINARY_IMAGE
echo "Removing parameter $param_name from task $TARGET_TASK"
remove_task_param "$TARGET_TASK" "$param_name" || :

while read -r param_name param_value
do
    if [ -z "$param_name" ]; then
        continue
    fi
    if ! task_param_exists "$TARGET_TASK" "$param_name"
    then
        echo "Adding parameter $param_name to task $TARGET_TASK"
        if ! add_task_param "$TARGET_TASK" "$param_name" "$param_value"
        then
            echo "Failed to add parameter ${param_name}:${param_value} to task $TARGET_TASK"
        fi
    fi
done <<<"$params"
