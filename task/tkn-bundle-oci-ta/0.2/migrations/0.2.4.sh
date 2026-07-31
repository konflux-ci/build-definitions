#!/usr/bin/env bash

set -euo pipefail

# Migration for tkn-bundle-oci-ta 0.2.4
# Removes the build-source-image parameter from the tkn-bundle builder pipeline

declare -r pipeline_file=${1:?missing pipeline file}

PARAMS_SELECTOR='(.spec.params[]?, .spec.pipelineSpec.params[]?)'

if ! yq -e "${PARAMS_SELECTOR} | select(.name == \"build-source-image\")" "$pipeline_file" >/dev/null 2>&1; then
  echo "build-source-image parameter not found, skipping"
  exit 0
fi

param_path=$(yq -o=json "${PARAMS_SELECTOR} | select(.name == \"build-source-image\") | path" "$pipeline_file")

pmt modify -f "$pipeline_file" \
    generic remove "$param_path"
