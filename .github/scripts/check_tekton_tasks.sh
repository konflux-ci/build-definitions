#!/bin/bash
shopt -s nullglob
set -euo pipefail

# <TEMPLATED FILE!>
# This file comes from the templates at https://github.com/konflux-ci/task-repo-shared-ci.
# Please consider sending a PR upstream instead of editing the file directly.
# See the SHARED-CI.md document in this repo for more details.

if [ "$#" -eq 0 ]; then
    echo "No changed task directories provided, nothing to validate"
    exit 0
fi

echo ">>> Applying and validating Tekton Tasks"

for TASK_DIR in "$@"; do
    TASK_NAME=$(basename "$(dirname "$TASK_DIR")")
    TASK_YAML_PATH="${TASK_DIR}/${TASK_NAME}.yaml"

    if [ -f "$TASK_YAML_PATH" ]; then
        echo ">>> Validating Task: $TASK_YAML_PATH"
        kubectl apply -f "$TASK_YAML_PATH" --dry-run=server
    else
        echo "INFO: Task YAML not found at '$TASK_YAML_PATH'. A non-YAML file was changed, skipping..."
    fi
done

echo ">>> All changed tasks validated successfully."
