#!/usr/bin/env bash

set -euo pipefail

declare -r pipeline_file=${1:?missing pipeline file}

TASKS_SELECTOR='(.spec.tasks[]?, .spec.pipelineSpec.tasks[]?)'

if ! yq -e "${TASKS_SELECTOR} | select(
  .taskRef.name == \"tkn-bundle\" or
  .taskRef.name == \"tkn-bundle-oci-ta\" or
  (.taskRef.params[] | select(.name == \"name\" and (.value == \"tkn-bundle\" or .value == \"tkn-bundle-oci-ta\")))
)" "$pipeline_file" >/dev/null 2>&1; then
  echo "Not a tekton-bundle-builder pipeline, skipping migration"
  exit 0
fi

# shellcheck disable=SC2016
pmt modify -f "$pipeline_file" \
    pipeline add-result \
    'SHOULD_RELEASE=$(tasks.build-container.results.SHOULD_RELEASE)'

pmt modify -f "$pipeline_file" \
    pipeline add-param \
    --description "Release the task bundle only when the app.kubernetes.io/version is different" \
    --type string \
    --default "true" \
    "release-only-if-version-bumped"

# shellcheck disable=SC2016
pmt modify -f "$pipeline_file" \
    task build-container add-param \
    "RELEASE_ONLY_IF_VERSION_BUMPED" '$(params.release-only-if-version-bumped)'

pmt modify -f "$pipeline_file" \
    task clone-repository add-param \
    "depth" "2"
