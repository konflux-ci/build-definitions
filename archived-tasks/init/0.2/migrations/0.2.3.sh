#!/usr/bin/env bash

set -euo pipefail

# Created for task: init@0.2.3
# Creation time: 2025-09-30T15:00:03Z

declare -r pipeline_file=${1:?missing pipeline file}


# Fixing migration from 0.2.1, where old FBC pipelines has been accidentally migrated to docker

if yq -e '.spec.params[] | select(.name == "buildah-format")' "$pipeline_file" >/dev/null; then
    # migration happened
    if yq -e '.spec.tasks[] | select(.taskRef.params[] | (.name == "name" and .value == "validate-fbc"))' "$pipeline_file" >/dev/null; then
       # it's older FBC pipeline with migration, switch to oci
       yq -i '.spec.params[] |= select( .name == "buildah-format").default = "oci"' "$pipeline_file"
       echo "Switching FBC pipeline back to OCI"
    fi
fi

# Fix harm done in 0.2.2 migration

if yq -e '.default' "$pipeline_file" >/dev/null; then
   yq -i 'del(.default)' "$pipeline_file"
fi

