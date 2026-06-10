#!/usr/bin/env bash

set -euo pipefail

# Created for task: init@0.3
# Creation time: 2026-01-28T11:28:34Z

declare -r pipeline_file=${1:?missing pipeline file}

#Remove rebuild param from .spec.PipelineSpec.params 
mapfile -t pipeline_spec_current_params < <(yq '.spec.pipelineSpec.params.[].name' "$pipeline_file")
for param_name in "${pipeline_spec_current_params[@]}"; do
  if [[ "$param_name" == "rebuild" ]]; then
    echo "Removing pipelineSpec param: ${param_name}"
    export param_name
    pmt modify -f "$pipeline_file" generic remove "$(yq '.spec.pipelineSpec.params.[] | select(.name == strenv(param_name)) | path' "$pipeline_file")"
  fi
done

# Remove rebuild param from .spec.params
mapfile -t pipeline_spec_current_params < <(yq '.spec.params.[].name' "$pipeline_file")
for param_name in "${pipeline_spec_current_params[@]}"; do
  if [[ "$param_name" == "rebuild" ]]; then
    echo "Removing spec param: ${param_name}"
    export param_name
    pmt modify -f "$pipeline_file" generic remove "$(yq '.spec.params.[] | select(.name == strenv(param_name)) | path' "$pipeline_file")"
  fi
done

#Remove init task params
echo "Removing init task params..."
pmt modify -f "$pipeline_file" task init remove-param image-url
pmt modify -f "$pipeline_file" task init remove-param rebuild
pmt modify -f "$pipeline_file" task init remove-param skip-checks

# Remove when expressions from .spec.pipelineSpec.tasks
mapfile -t pipeline_task_with_when < <(yq '.spec.pipelineSpec.tasks.[] | select (.when != null).name' "$pipeline_file")
for task_name in "${pipeline_task_with_when[@]}"; do
   export task_name
   # shellcheck disable=SC2016
   if yq -e '.spec.pipelineSpec.tasks.[] | select (.name == strenv(task_name)) | .when[] | select(.input == "$(tasks.init.results.build)") | path' "$pipeline_file" >/tmp/path.yaml 2>&1; then
    pmt modify -f "$pipeline_file" generic remove "$(cat /tmp/path.yaml)"
   fi
done

# Remove when expressions from .spec.tasks
mapfile -t pipeline_task_with_when < <(yq '.spec.tasks.[] | select (.when != null).name' "$pipeline_file")
for task_name in "${pipeline_task_with_when[@]}"; do
   export task_name
   # shellcheck disable=SC2016
   if yq -e '.spec.tasks.[] | select (.name == strenv(task_name)) | .when[] | select(.input == "$(tasks.init.results.build)") | path' "$pipeline_file" >/tmp/path.yaml 2>&1; then
    pmt modify -f "$pipeline_file" generic remove "$(cat /tmp/path.yaml)"
   fi
done

# Remove when expressions from .spec.finally
mapfile -t pipeline_task_with_when < <(yq '.spec.finally.[] | select (.when != null).name' "$pipeline_file")
for task_name in "${pipeline_task_with_when[@]}"; do
   export task_name
   # shellcheck disable=SC2016
   if yq -e '.spec.finally.[] | select (.name == strenv(task_name)) | .when[] | select(.input == "$(tasks.init.results.build)") | path' "$pipeline_file" >/tmp/path.yaml 2>&1; then
    pmt modify -f "$pipeline_file" generic remove "$(cat /tmp/path.yaml)"
   fi
done