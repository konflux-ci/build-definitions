#!/usr/bin/env bash

set -euo pipefail

declare -r pipeline_file=${1:?missing pipeline file}

declare -r GIT_URL="https://github.com/konflux-ci/tekton-integration-catalog.git"
declare -r GIT_REVISION="2a46aa279f37ae0ed9966e451024c9ddcc669d0b"
declare -r GIT_PATH="tasks/slack-webhook-notification/0.1/slack-webhook-notification.yaml"

TASKS_SELECTOR='(.spec.tasks[]?, .spec.finally[]?, .spec.pipelineSpec.tasks[]?, .spec.pipelineSpec.finally[]?)'
TASK_SELECTOR="${TASKS_SELECTOR} | select(
  .taskRef.name == \"slack-webhook-notification\" or
  (.taskRef.params[] | (.name == \"name\" and .value == \"slack-webhook-notification\"))
)"

if ! yq -e "${TASK_SELECTOR}" "$pipeline_file" >/dev/null 2>&1; then
  echo "slack-webhook-notification bundle not found, skipping"
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
  echo "updating slack-webhook-notification taskRef at ${taskref_path} to git resolver"
  pmt modify -f "$pipeline_file" generic replace "$taskref_path" "$new_taskref"
done
