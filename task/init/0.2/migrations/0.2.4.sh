#!/usr/bin/env bash

set -euo pipefail

# Created for task: init@0.2.4
# Creation time: 2025-09-30T15:00:53Z

declare -r pipeline_file=${1:?missing pipeline file}


buildah_format="docker"


# Fix harm done in 0.2.2 migration
if yq -e '.default' "$pipeline_file" >/dev/null; then
   yq -i 'del(.default)' "$pipeline_file"
fi


# Fixing migration from 0.2.1, where old FBC pipelines has been accidentally migrated to docker
if yq -e '.spec.params[] | select(.name == "buildah-format")' "$pipeline_file" >/dev/null; then
    # migration happened
    if yq -e '.spec.tasks[] | select(.taskRef.params[] | (.name == "name" and .value == "validate-fbc"))' "$pipeline_file" >/dev/null; then
       # it's older FBC pipeline with migration, switch to oci
       yq -i '.spec.params[] |= select( .name == "buildah-format").default = "oci"' "$pipeline_file"
       echo "Switching FBC pipeline back to OCI"
    fi
fi


# Check if the run-opm-command task exists, FBC pipeline must be OCI by default
if yq -e '.spec.tasks[] | select(.name == "run-opm-command")' "$pipeline_file" >/dev/null; then
    echo "FBC pipeline detected, skipping"
    exit 0
fi

# Fix migration from 0.2.3 where we omitted old style FBC pipelines
# Check if the run-opm-command task exists, FBC pipeline must be OCI by default
if yq -e '.spec.tasks[] | select(.taskRef.params[] | (.name == "name" and .value == "validate-fbc"))' "$pipeline_file" >/dev/null; then
    echo "FBC pipeline detected, skipping"
    exit 0
fi


# Tekton bundle build pipeline must be OCI by default
if yq -e '.spec.tasks[] | select(.taskRef.params[] | (.name == "name" and (.value == "tkn-bundle" or .value == "tkn-bundle-oci-ta")))' "$pipeline_file" >/dev/null; then
    echo "Tekton bundle build pipeline detected, skipping"
    exit 0
fi


buildah_format_tasks=( \
  "buildah-min" "buildah" "buildah-oci-ta" \
  "buildah-remote" "buildah-remote-oci-ta" \
  "build-image-index" "build-image-manifest" \
  # sast tasks have BUILDAH_FORMAT param, but we can ignore them, as image is ephemeral for testing only
  # "sast-coverity-check" "sast-coverity-check-oci-ta" \
)
# Determine all tasks which should be updated
tasks_to_be_updated=()

# lookup for tasks by references, not by names as we need exactly these tasks, to avoid name colision
for task_refname in "${buildah_format_tasks[@]}"; do
    if yq -e ".spec.tasks[] | select(.taskRef.params[] | (.name == \"name\" and .value == \"${task_refname}\"))" "$pipeline_file" >/dev/null; then
        tasks_to_be_updated+=( "$(yq -e ".spec.tasks[] | select(.taskRef.params[] | (.name == \"name\" and .value == \"${task_refname}\")).name" "${pipeline_file}")" )
    fi
done

if [ ${#tasks_to_be_updated[@]} -eq 0 ]; then
    echo "No tasks marked for update"
    exit 0
fi


if yq -e '.spec.params[] | select(.name == "buildah-format")' "$pipeline_file" >/dev/null; then
    echo "Pipeline param buildah-format already exist, skipping migration"
    exit 0
fi

for build_taskname_value in "${tasks_to_be_updated[@]}"; do
    # Check if the task already has the BUILDAH_FORMAT parameter
    if yq -e ".spec.tasks[] | select(.name == \"$build_taskname_value\").params[] | select(.name == \"BUILDAH_FORMAT\")" "$pipeline_file" >/dev/null; then
        echo "BUILDAH_FORMAT parameter already exists in $build_taskname_value task. Skipping migration"
        exit 0
    fi
done

# Update all relevant tasks
echo "Adding buildah-format pipeline param"
yq -i ".spec.params += [{\
    \"name\": \"buildah-format\",\
    \"default\": \"${buildah_format}\",\
    \"type\": \"string\",\
    \"description\": \"The format for the resulting image's mediaType. Valid values are oci or docker.\"\
}]" "$pipeline_file"

for build_taskname_value in "${tasks_to_be_updated[@]}"; do
    echo "Adding BUILDAH_PARAM into task ${build_taskname_value}"
    yq -i "(.spec.tasks[] | select(.name == \"$build_taskname_value\")).params += [{\"name\": \"BUILDAH_FORMAT\", \"value\": \"\$(params.buildah-format)\"}]" "$pipeline_file"
done
