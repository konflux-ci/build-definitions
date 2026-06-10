#!/usr/bin/env bash

set -euo pipefail

# Created for task: init@0.4.2
# Creation time: 2026-05-07T00:00:00+00:00

declare -r pipeline_file=${1:?missing pipeline file}

if [[ "$(yq '.kind' "$pipeline_file")" != "PipelineRun" ]]; then
    echo "Not a PipelineRun, skipping migration"
    exit 0
fi

if ! yq -e '.spec.params[] | select(.name == "sast-target-dirs")' "$pipeline_file" >/dev/null 2>&1; then
    echo "No sast-target-dirs parameter found in spec.params, skipping migration"
    exit 0
fi

if yq -e '.spec.params[] | select(.name == "sast-target-dirs") | has("value")' "$pipeline_file" 2>/dev/null | grep -q true; then
    echo "sast-target-dirs parameter in spec.params has a value, most likely already fixed, no update needed"
    exit 0
fi

echo "Removing sast-target-dirs parameter from spec.params (no value attribute)"
pmt_path=$(yq '.spec.params[] | select(.name == "sast-target-dirs") | path | tojson' "$pipeline_file")
pmt modify -f "$pipeline_file" generic remove "$pmt_path"
