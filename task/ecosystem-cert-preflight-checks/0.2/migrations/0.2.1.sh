#!/usr/bin/env bash

set -euo pipefail

# Created for task: ecosystem-cert-preflight-checks@0.2.1
# Creation time: 2025-07-21T06:38:31+00:00

declare -r pipeline_file=${1:?missing pipeline file}

# Check if the pipeline has 'build-platforms' parameter
if ! yq -e '.spec.params[] | select(.name == "build-platforms")' "$pipeline_file" >/dev/null 2>&1; then
  echo "Matrix will not be added because the dependent parameter 'build-platforms' is not defined in the pipeline."
  exit 0
fi

# Check if the task exists
if ! yq -e '.spec.tasks[] | select(.name == "ecosystem-cert-preflight-checks")' "$pipeline_file" >/dev/null 2>&1; then
  echo "Task 'ecosystem-cert-preflight-checks' does not exist in the pipeline."
  exit 0
fi

# Check if the task already has a matrix
if yq -e '.spec.tasks[] | select(.name == "ecosystem-cert-preflight-checks") | has("matrix")' "$pipeline_file" >/dev/null 2>&1; then
  echo "Matrix already exists for task 'ecosystem-cert-preflight-checks'. No changes made."
else
  echo "Adding matrix for task 'ecosystem-cert-preflight-checks'..."
  yq -i "
  (.spec.tasks[] 
    | select(.name == \"ecosystem-cert-preflight-checks\" and .matrix == null)
  ).matrix = {
    \"params\": [
      {
        \"name\": \"platform\",
        \"value\": [\"\$(params.build-platforms)\"]
      }
    ]
  }
" "$pipeline_file"

  echo "Adding matrix for task 'ecosystem-cert-preflight-checks' completed!"
fi
