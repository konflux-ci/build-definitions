#!/usr/bin/env bash

set -euo pipefail

# Created for task: init@0.4.1
# Creation time: 2026-04-27T03:57:04+00:00

declare -r pipeline_file=${1:?missing pipeline file}

sast_task_refs=(
    "sast-coverity-check" "sast-coverity-check-oci-ta"
    "sast-shell-check" "sast-shell-check-oci-ta" "sast-shell-check-oci-ta-min"
    "sast-snyk-check" "sast-snyk-check-oci-ta"
    "sast-unicode-check" "sast-unicode-check-oci-ta" "sast-unicode-check-oci-ta-min"
)

tasks_selector="(.spec.tasks[], .spec.pipelineSpec.tasks[])"

all_sast_tasks=()
for task_refname in "${sast_task_refs[@]}"; do
    task_filter="${tasks_selector} | select(.taskRef.params[] | (.name == \"name\" and .value == \"${task_refname}\"))"
    if yq -e "$task_filter" "$pipeline_file" >/dev/null 2>&1; then
        readarray -t -O ${#all_sast_tasks[@]} all_sast_tasks < <(yq -e "${task_filter} | .name" "$pipeline_file")
    fi
done

if [ ${#all_sast_tasks[@]} -eq 0 ]; then
    echo "No SAST tasks found, skipping migration"
    exit 0
fi

# Check if any SAST task already has a custom TARGET_DIRS value to preserve
existing_target_dirs=""
for task_name in "${all_sast_tasks[@]}"; do
    [[ -z "$task_name" ]] && continue
    for params_path in ".spec.tasks[]" ".spec.pipelineSpec.tasks[]"; do
        value=$(yq -e "(${params_path} | select(.name == \"${task_name}\")).params[] | select(.name == \"TARGET_DIRS\").value" "$pipeline_file" 2>/dev/null) || continue
        # shellcheck disable=SC2016
        if [[ -n "$value" && "$value" != "." && "$value" != '$(params.sast-target-dirs)' ]]; then
            echo "Found existing TARGET_DIRS value on task ${task_name}: ${value}"
            existing_target_dirs="$value"
            break 2
        fi
    done
done

default_value="${existing_target_dirs:-.}"

# Add sast-target-dirs pipeline-level parameter
param_value="{\"name\": \"sast-target-dirs\", \"type\": \"string\", \"default\": \"${default_value}\", \"description\": \"Target directories to scan with SAST tools. Multiple values should be separated with commas.\"}"

# Pipeline format: .spec.params
if yq -e '.spec.params' "$pipeline_file" >/dev/null 2>&1; then
    if ! yq -e '.spec.params[] | select(.name == "sast-target-dirs")' "$pipeline_file" >/dev/null 2>&1; then
        echo "Adding sast-target-dirs parameter to .spec.params (default: ${default_value})"
        pmt modify -f "$pipeline_file" generic insert '["spec", "params"]' "$param_value"
    fi
fi

# PipelineRun format: .spec.pipelineSpec.params
if yq -e '.spec.pipelineSpec.params' "$pipeline_file" >/dev/null 2>&1; then
    if ! yq -e '.spec.pipelineSpec.params[] | select(.name == "sast-target-dirs")' "$pipeline_file" >/dev/null 2>&1; then
        echo "Adding sast-target-dirs parameter to .spec.pipelineSpec.params (default: ${default_value})"
        pmt modify -f "$pipeline_file" generic insert '["spec", "pipelineSpec", "params"]' "$param_value"
    fi
fi

# Wire TARGET_DIRS on all SAST tasks to the pipeline-level parameter
for task_name in "${all_sast_tasks[@]}"; do
    [[ -z "$task_name" ]] && continue
    echo "Wiring TARGET_DIRS on task ${task_name} to \$(params.sast-target-dirs)"
    # shellcheck disable=SC2016
    pmt modify -f "$pipeline_file" task "${task_name}" add-param TARGET_DIRS '$(params.sast-target-dirs)'
done
