#!/usr/bin/env bash
set -euo pipefail

declare -r pipeline_file=${1:?missing pipeline file}

TASKS_SELECTOR='(.spec.tasks[]?, .spec.pipelineSpec.tasks[]?, .spec.finally[]?, .spec.pipelineSpec.finally[]?)'

if ! yq -e "${TASKS_SELECTOR} | select(.name == \"show-summary\")" "$pipeline_file" >/dev/null 2>&1; then
  echo "show-summary not found, skipping"
  exit 0
fi

pmt_path=$(yq -o=json "${TASKS_SELECTOR} | select(.name == \"show-summary\") | path" "$pipeline_file")
pmt modify -f "$pipeline_file" generic remove "$pmt_path"
