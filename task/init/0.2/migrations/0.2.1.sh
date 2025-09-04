#!/usr/bin/env bash

set -euo pipefail

# Created for task: init@0.2.1
# Creation time: 2025-09-19T10:00:53Z

declare -r pipeline_file=${1:?missing pipeline file}


buildah_format="docker"
# Check if the run-opm-command task exists
if yq -e '.spec.tasks[] | select(.name == "run-opm-command")' "$pipeline_file" >/dev/null; then
    # FBC builder needs to be OCI by default
    echo "FBC pipeline detected, setting format to oci"
    buildah_format="oci"
fi

if yq -e '.spec.tasks[] | select(.taskRef.params[] | (.name == "name" and (.value == "tkn-bundle" or .value == "tkn-bundle-oci-ta")))' "$pipeline_file" >/dev/null; then
    # Tekton bundle should be OCI
    echo "Tekton bundle pipeline detected, setting format to oci"
    buildah_format="oci"
fi


# Determine all tasks which should be updated
tasks_to_be_updated=()

if yq -e '.spec.tasks[] | select(.name == "build-images")' "$pipeline_file" >/dev/null; then
    tasks_to_be_updated+=( "build-images" )
fi

if yq -e '.spec.tasks[] | select(.name == "build-container")' "$pipeline_file" >/dev/null; then
    tasks_to_be_updated+=( "build-container" )
fi

if yq -e '.spec.tasks[] | select(.name == "build-image-index")' "$pipeline_file" >/dev/null; then
    tasks_to_be_updated+=( "build-image-index" )
fi

# this is special, I couldn't find what would be the common name, thus getting task via ref
if yq -e '.spec.tasks[] | select(.taskRef.params[] | (.name == "name" and .value == "build-image-manifest"))' "$pipeline_file" >/dev/null; then
    tasks_to_be_updated+=( "$(yq -e '.spec.tasks[] | select(.taskRef.params[] | (.name == "name" and .value == "build-image-manifest")).name' "$pipeline_file")" )
fi

if [ ${#tasks_to_be_updated[@]} -eq 0 ]; then
    echo "No tasks for update"
    exit 0
fi


# Update pipeline params (only if some relevant tasks exist)
if yq -e '.spec.params[] | select(.name == "buildah-format")' "$pipeline_file" >/dev/null; then
    echo "Pipeline param buildah-format already exist, skipping migration"
    exit 0
else
    echo "Adding buildah-format pipeline param"
    yq -i ".spec.params += [{\
       \"name\": \"buildah-format\",\
       \"default\": \"$buildah_format\",\
       \"type\": \"string\",\
       \"description\": \"The format for the resulting image's mediaType. Valid values are oci or docker.\"\
    }]" "$pipeline_file"
fi

# Update all relevant tasks
for build_taskname_value in "${tasks_to_be_updated[@]}"; do
    echo "processing task ${build_taskname_value}"
    # Check if the task already has the BUILDAH_FORMAT parameter
    if ! yq -e ".spec.tasks[] | select(.name == \"$build_taskname_value\").params[] | select(.name == \"BUILDAH_FORMAT\")" "$pipeline_file" >/dev/null; then
        echo "Adding BUILDAH_FORMAT parameter to $build_taskname_value task"
        yq -i "(.spec.tasks[] | select(.name == \"$build_taskname_value\")).params += [{\"name\": \"BUILDAH_FORMAT\", \"value\": \"\$(params.buildah-format)\"}]" "$pipeline_file"
    else
        echo "BUILDAH_FORMAT parameter already exists in $build_taskname_value task. No changes needed."
    fi
done
