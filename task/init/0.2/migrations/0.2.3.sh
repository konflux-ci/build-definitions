#!/usr/bin/env bash

set -euo pipefail

# Created for task: init@0.2.3
# Creation time: 2025-09-29T20:13:24Z

declare -r pipeline_file=${1:?missing pipeline file}

# Fix paths from 0.2.2, where it was pointing to spec.params rather than the pipeline defaults.
# Fixing migration from 0.2.1, where old FBC pipelines has been accidentally migrated to docker

echo "* Checking for buildah-format parameter in FBC pipelineSpec"

if yq -e '.spec.pipelineSpec.params[] | select(.name == "buildah-format")' "$pipeline_file" >/dev/null; then
    # migration happened
    echo "* Checking for validate-fbc task in pipelineSpec"
    if yq -e '.spec.pipelineSpec.tasks[] | select(.taskRef.params[] | (.name == "name" and .value == "validate-fbc"))' "$pipeline_file" >/dev/null; then
       # it's older FBC pipeline with migration, switch to oci
       echo "* Switching FBC pipeline back to OCI"
       yq -i '.spec.pipelineSpec.params[] |= select( .name == "buildah-format").default = "oci"' "$pipeline_file"
    fi
fi

echo "* Migration to init@0.2.3 complete"
