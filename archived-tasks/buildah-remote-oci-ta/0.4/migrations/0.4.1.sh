#!/usr/bin/env bash

set -euo pipefail

# Created for task: buildah@0.4.1
# Creation time: 2025-09-12T11:28:54Z

declare -r pipeline_file=${1:?missing pipeline file}

# Check if the clone-repository task exists
if yq -e '.spec.tasks[] | select(.name == "clone-repository")' "$pipeline_file" >/dev/null; then
    source_url_value="\$(tasks.clone-repository.results.url)"
else
    echo "Task 'clone-repository' does not exist in the pipeline."
    exit 0
fi

# Determine the correct build task name
if yq -e '.spec.tasks[] | select(.name == "build-images")' "$pipeline_file" >/dev/null; then
    build_taskname_value="build-images"
elif yq -e '.spec.tasks[] | select(.name == "build-container")' "$pipeline_file" >/dev/null; then
    build_taskname_value="build-container"
else
    echo "Neither build-images nor build-container tasks found."
    exit 0
fi

# Check if the task already has the SOURCE_URL parameter
if ! yq -e ".spec.tasks[] | select(.name == \"$build_taskname_value\").params[] | select(.name == \"SOURCE_URL\")" "$pipeline_file" >/dev/null; then
    echo "Adding SOURCE_URL parameter to $build_taskname_value task"
    yq -i "(.spec.tasks[] | select(.name == \"$build_taskname_value\")).params += [{\"name\": \"SOURCE_URL\", \"value\": \"$source_url_value\"}]" "$pipeline_file"
else
    echo "SOURCE_URL parameter already exists in $build_taskname_value task. No changes needed."
fi

