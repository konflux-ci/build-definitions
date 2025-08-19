#!/usr/bin/env bash

set -euo pipefail

# Created for task: tkn-bundle@0.2
# Creation time: 2025-08-15

declare -r pipeline_file=${1:?missing pipeline file}

# Check if depth parameter already exists in task clone-repository if tkn-bundle* task exists in pipeline
if yq -e '.spec.tasks[] | select(.name == "build-container").taskRef.params[] | select(.name == "name" and .value == "tkn-bundle")' "$pipeline_file" >/dev/null 2>/dev/null && ! yq -e '.spec.tasks[] | select(.name == "clone-repository").params[] | select(.name == "depth")' "$pipeline_file" >/dev/null 2>/dev/null; then
    echo "set depth to 100 in clone-repository task if tkn-bundle task exists in pipeline"
    yq -i "(.spec.tasks[] | select(.name == \"clone-repository\")).params += [{\"name\": \"depth\", \"value\": \"100\"}]" "$pipeline_file"
else
    echo "depth parameter already exists in clone-repository task or task tkn-bundle doesn't exist. No changes needed."
fi
