#!/usr/bin/env bash

set -euo pipefail

# Created for task: clamav-scan@0.3
# Creation time: 2025-07-21T01:11:59+00:00

declare -r pipeline_file=${1:?missing pipeline file}
TASK_NAME="clamav-scan"

# Check if the pipeline has 'build-platforms' parameter
if ! yq -e '.spec.params[] | select(.name == "build-platforms")' "$pipeline_file" >/dev/null 2>&1; then
  echo "Matrix will not be added because the dependent parameter 'build-platforms' is not defined in the pipeline."
  exit 0
fi

# Check if the task exists
if ! yq -e '.spec.tasks[] | select(.name == "'"$TASK_NAME"'")' "$pipeline_file" >/dev/null 2>&1; then
  echo "Task '$TASK_NAME' does not exist in the pipeline."
  exit 0
fi

# Check if the task already has a matrix
#if yq -e '.spec.tasks[] | select(.name == "'"$TASK_NAME"'") | has("matrix")' "$pipeline_file" >/dev/null 2>&1; then
#  echo "Matrix already exists for task '$TASK_NAME'. No changes made."
#else
#  echo "Adding matrix for task '$TASK_NAME'..."
#  yq -i "
#  (.spec.tasks[]
#    | select(.name == \"clamav-scan\" and .matrix == null)
#  ).matrix = {
#    \"params\": [
#      {
#        \"name\": \"image-arch\",
#        \"value\": [\"\$(params.build-platforms)\"]
#      }
#    ]
#  }
#" "$pipeline_file"
#
#  echo "Adding matrix for task '$TASK_NAME' completed!"
#fi
