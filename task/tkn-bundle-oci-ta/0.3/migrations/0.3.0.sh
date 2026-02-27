#!/usr/bin/env bash

set -euo pipefail

# Migration for tkn-bundle-oci-ta 0.3.0
# Adds the optional STEPS_IMAGE_STEP_NAMES parameter to the build-container task.

declare -r pipeline_file=${1:?missing pipeline file}

pmt modify -f "$pipeline_file" \
    task build-container \
    add-param STEPS_IMAGE_STEP_NAMES ""
