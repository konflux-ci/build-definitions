#!/usr/bin/env bash

set -euo pipefail

# Created for task: fbc-fips-check-oci-ta@0.2
# Migration: Convert standalone fbc-fips-check-oci-ta to matrix mode with prepare task
#
# NOTE: v0.2 is designed for matrix mode and requires different parameters than v0.1.
#       - v0.1: Standalone mode (SOURCE_ARTIFACT, image-digest, image-url)
#       - v0.2: Matrix mode (BUCKETS_ARTIFACT, BUCKET_INDEX) with fbc-fips-prepare-oci-ta
#
#       This script adds fbc-fips-prepare-oci-ta and rewires fbc-fips-check-oci-ta for
#       parallel processing. If you prefer standalone mode, continue using v0.1.

declare -r pipeline_file=${1:?missing pipeline file}

# Combined selector for tasks in both Pipeline and PipelineRun
TASKS_SELECTOR="(.spec.tasks[], .spec.pipelineSpec.tasks[])"

# Check if the fbc-fips-check-oci-ta task exists
if ! yq -e "${TASKS_SELECTOR} | select(.taskRef.params[] | select(.name == \"name\" and .value == \"fbc-fips-check-oci-ta\"))" "$pipeline_file" >/dev/null 2>&1; then
  echo "Task 'fbc-fips-check-oci-ta' not found in the pipeline. Skipping matrix mode migration."
  exit 0
fi

# Get the task name (the .name field, not the taskRef name)
task_name=$(yq -e "${TASKS_SELECTOR} | select(.taskRef.params[] | select(.name == \"name\" and .value == \"fbc-fips-check-oci-ta\")) | .name" "$pipeline_file")
echo "Found fbc-fips-check task: $task_name"

# Check if prepare task already exists
if yq -e "${TASKS_SELECTOR} | select(.name == \"fbc-fips-prepare-oci-ta\")" "$pipeline_file" >/dev/null 2>&1; then
  echo "Task 'fbc-fips-prepare-oci-ta' already exists. Matrix mode migration may have been applied."
  exit 0
fi

# Check if the check task already has a matrix
if yq -e "${TASKS_SELECTOR} | select(.name == \"${task_name}\") | .matrix" "$pipeline_file" 2>/dev/null | grep -q "params"; then
  echo "Matrix already exists for task '$task_name'. No changes made."
  exit 0
fi

echo "Migrating fbc-fips-check-oci-ta to matrix mode..."

# Extract current task parameters for the prepare task
source_artifact=$(yq -e "${TASKS_SELECTOR} | select(.name == \"${task_name}\") | .params[] | select(.name == \"SOURCE_ARTIFACT\") | .value" "$pipeline_file" 2>/dev/null || echo "\$(tasks.clone-repository.results.SOURCE_ARTIFACT)")
image_digest=$(yq -e "${TASKS_SELECTOR} | select(.name == \"${task_name}\") | .params[] | select(.name == \"image-digest\") | .value" "$pipeline_file" 2>/dev/null || echo "\$(tasks.build-container.results.IMAGE_DIGEST)")
image_url=$(yq -e "${TASKS_SELECTOR} | select(.name == \"${task_name}\") | .params[] | select(.name == \"image-url\") | .value" "$pipeline_file" 2>/dev/null || echo "\$(tasks.build-container.results.IMAGE_URL)")

# Get all runAfter dependencies from existing task (as JSON array)
run_after_json=$(yq -o=json "${TASKS_SELECTOR} | select(.name == \"${task_name}\") | .runAfter // []" "$pipeline_file")

# ociStorage with suffix to avoid conflict with output-image
oci_storage="\$(params.output-image)-fbc-fips-check"

# Determine paths based on whether it is a Pipeline or PipelineRun
if yq -e '.spec.pipelineSpec' "$pipeline_file" >/dev/null 2>&1; then
  # PipelineRun with embedded spec
  TASKS_PATH='["spec", "pipelineSpec", "tasks"]'
else
  # Pipeline
  TASKS_PATH='["spec", "tasks"]'
fi

echo "Adding fbc-fips-prepare-oci-ta task..."

# Build the prepare task JSON using bundles resolver
prepare_task_json=$(cat <<EOF
{
  "name": "fbc-fips-prepare-oci-ta",
  "taskRef": {
    "resolver": "bundles",
    "params": [
      {"name": "name", "value": "fbc-fips-prepare-oci-ta"},
      {"name": "bundle", "value": "quay.io/konflux-ci/tekton-catalog/task-fbc-fips-prepare-oci-ta:0.1"},
      {"name": "kind", "value": "task"}
    ]
  },
  "params": [
    {"name": "SOURCE_ARTIFACT", "value": "${source_artifact}"},
    {"name": "image-digest", "value": "${image_digest}"},
    {"name": "image-url", "value": "${image_url}"},
    {"name": "ociStorage", "value": "${oci_storage}"}
  ]
}
EOF
)

# Add runAfter if the original task had dependencies
if [[ "$run_after_json" != "[]" && "$run_after_json" != "null" ]]; then
  prepare_task_json=$(echo "$prepare_task_json" | yq -o=json ".runAfter = ${run_after_json}")
fi

# Append the prepare task to the tasks list
# Note: The task will be appended at the end of the tasks list, but execution order
# is determined by runAfter, not position in the YAML file
pmt modify -f "$pipeline_file" generic insert "$TASKS_PATH" "$prepare_task_json"

echo "Updating $task_name to use matrix mode..."

# Get the path to the task for generic operations
task_path=$(yq -o=json "${TASKS_SELECTOR} | select(.name == \"${task_name}\") | path" "$pipeline_file")

# Update runAfter for check task to depend on prepare task
if yq -e "${TASKS_SELECTOR} | select(.name == \"${task_name}\") | .runAfter" "$pipeline_file" >/dev/null 2>&1; then
  # runAfter exists, use replace
  run_after_path=$(yq -o=json "${TASKS_SELECTOR} | select(.name == \"${task_name}\") | .runAfter | path" "$pipeline_file")
  pmt modify -f "$pipeline_file" generic replace "$run_after_path" '["fbc-fips-prepare-oci-ta"]'
else
  # runAfter doesn't exist, use insert
  pmt modify -f "$pipeline_file" generic insert "$task_path" '{"runAfter": ["fbc-fips-prepare-oci-ta"]}'
fi

# Remove old parameters from check task
pmt modify -f "$pipeline_file" task "$task_name" remove-param SOURCE_ARTIFACT
pmt modify -f "$pipeline_file" task "$task_name" remove-param image-digest
pmt modify -f "$pipeline_file" task "$task_name" remove-param image-url

# Add new parameters for matrix mode
pmt modify -f "$pipeline_file" task "$task_name" add-param BUCKETS_ARTIFACT "\$(tasks.fbc-fips-prepare-oci-ta.results.BUCKETS_ARTIFACT)"

# Add matrix expansion
pmt modify -f "$pipeline_file" generic insert \
  "$task_path" \
  "{\"matrix\": {\"params\": [{\"name\": \"BUCKET_INDEX\", \"value\": [\"\$(tasks.fbc-fips-prepare-oci-ta.results.BUCKET_INDICES[*])\"]}]}}"

echo "Migration to matrix mode completed successfully!"
echo "- Added 'fbc-fips-prepare-oci-ta' task"
echo "- Updated '$task_name' task with matrix expansion"
echo ""
echo "Note: If you prefer standalone mode, continue using v0.1 instead of v0.2."
