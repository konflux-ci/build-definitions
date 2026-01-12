#!/usr/bin/env bash

set -euo pipefail

# Created for task: clair-scan@0.3
# Creation time: 2025-08-21T01:52:31+00:00

declare -r pipeline_file=${1:?missing pipeline file}

# Check if the pipeline has 'build-platforms' parameter
if ! yq -e '.spec.params[] | select(.name == "build-platforms")' "$pipeline_file" >/dev/null 2>&1; then
  echo "Matrix will not be added because the dependent parameter 'build-platforms' is not defined in the pipeline."
  exit 0
fi

# Check if the task exists
if ! yq -e '.spec.tasks[] | select(.name == "clair-scan")' "$pipeline_file" >/dev/null 2>&1; then
  echo "Task 'clair-scan' does not exist in the pipeline."
  exit 0
fi

# Check if the task already has a matrix
if yq -e '.spec.tasks[] | select(.name == "clair-scan") | has("matrix")' "$pipeline_file" >/dev/null 2>&1; then
  echo "Matrix already exists for task 'clair-scan'. No changes made."
else
  echo "Adding matrix for task 'clair-scan'..."
  yq -i "
    (.spec.tasks[] | select(.name == \"clair-scan\" and .matrix == null)) |=
      {
        \"matrix\": {
          \"params\": [
            {
              \"name\": \"image-platform\",
              \"value\": [\"\$(params.build-platforms)\"]
            }
          ]
        }
      } + .
  " "$pipeline_file"

  echo "Adding matrix for task 'clair-scan' completed!"
fi
