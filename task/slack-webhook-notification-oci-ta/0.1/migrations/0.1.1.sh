#!/usr/bin/env bash

set -euo pipefail

declare -r pipeline_file=${1:?missing pipeline file}

declare -r GIT_URL="https://github.com/konflux-ci/tekton-integration-catalog.git"
declare -r GIT_REVISION="30fdd82dd35e142993e25667d3cd88ad6ff76ccf"
declare -r GIT_PATH="tasks/slack-webhook-notification-oci-ta/0.1/slack-webhook-notification-oci-ta.yaml"

TASKS_SELECTOR='(.spec.tasks[]?, .spec.finally[]?, .spec.pipelineSpec.tasks[]?, .spec.pipelineSpec.finally[]?)'
TASK_SELECTOR="${TASKS_SELECTOR} | select(
  .taskRef.name == \"slack-webhook-notification-oci-ta\" or
  (.taskRef.params[] | (.name == \"name\" and .value == \"slack-webhook-notification-oci-ta\"))
)"

if ! yq -e "${TASK_SELECTOR}" "$pipeline_file" >/dev/null 2>&1; then
  echo "slack-webhook-notification-oci-ta bundle not found, skipping"
  exit 0
fi

readarray -t taskref_paths < <(
  yq -o=json --indent=0 "${TASK_SELECTOR} | .taskRef | path" "$pipeline_file"
)

new_taskref="{
  \"resolver\": \"git\",
  \"params\": [
    {\"name\": \"url\", \"value\": \"${GIT_URL}\"},
    {\"name\": \"revision\", \"value\": \"${GIT_REVISION}\"},
    {\"name\": \"pathInRepo\", \"value\": \"${GIT_PATH}\"}
  ]
}"

for taskref_path in "${taskref_paths[@]}"; do
  echo "updating slack-webhook-notification-oci-ta taskRef at ${taskref_path} to git resolver"
  pmt modify -f "$pipeline_file" generic replace "$taskref_path" "$new_taskref"
done
