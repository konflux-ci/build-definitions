#!/usr/bin/env bash

set -euo pipefail

# Created for task: init@0.3
# Creation time: 2026-01-21T11:28:34Z

declare -r pipeline_file=${1:?missing pipeline file}

#Remove rebuild and skip-checks params from .spec.PipelineSpec.params
mapfile -t pipeline_spec_current_params < <(yq '.spec.pipelineSpec.params.[].name' "$pipeline_file")
for param_name in "${pipeline_spec_current_params[@]}"; do
  if [[ "$param_name" == "rebuild" || "$param_name" == "skip-checks" ]]; then
    echo "Removing pipelineSpec param: ${param_name}"
    export param_name
    pmt modify -f "$pipeline_file" generic remove "$(yq '.spec.pipelineSpec.params.[] | select(.name == strenv(param_name)) | path' "$pipeline_file")"
  fi
done

#Remove init task params
echo "Removing init task params..."
pmt modify -f "$pipeline_file" task init remove-param image-url
pmt modify -f "$pipeline_file" task init remove-param rebuild
pmt modify -f "$pipeline_file" task init remove-param skip-checks

# Remove when expressions from tasks
target_tasks=("clone-repository" "build-container" "build-images" "build-image-index" "deprecated-base-image-check" "clair-scan" "ecosystem-cert-preflight-checks" \
   "sast-snyk-check" "clamav-scan" "coverity-availability-check" "sast-shell-check" "sast-unicode-check" "rpms-signature-scan" "validate-fbc" "fbc-target-index-pruning-check" "fbc-fips-check-oci-ta")

mapfile -t pipeline_task_names < <(yq '.spec.pipelineSpec.tasks.[].name' "$pipeline_file")
for task_name in "${pipeline_task_names[@]}"; do
  if grep -q "\b$task_name\b" <<< "${target_tasks[*]// /|}"; then
    echo "Updating when expression of task: $task_name"
    export task_name
    pmt modify -f "$pipeline_file" generic remove "$(yq '.spec.pipelineSpec.tasks.[] | select (.name == strenv(task_name)).when | path' "$pipeline_file")"
  elif [[ $task_name == "build-source-image" || $task_name == "sast-coverity-check" ]]; then
    echo "Updating when expression of task: $task_name"
    export task_name
    pmt modify -f "$pipeline_file" generic remove "$(yq '.spec.pipelineSpec.tasks.[] | select (.name == strenv(task_name)).when.[0] | path' "$pipeline_file")"
  fi
done
