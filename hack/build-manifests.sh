#!/bin/bash -e

# <TEMPLATED FILE!>
# This file comes from the templates at https://github.com/konflux-ci/task-repo-shared-ci.
# Please consider sending a PR upstream instead of editing the file directly.
# See the SHARED-CI.md document in this repo for more details.

# To make the script work on linux and mac, use '${SED_CMD}' instead of 'sed'
# https://stackoverflow.com/a/4247319
if [[ "$OSTYPE" == "darwin"* ]]; then
  # Require gnu-sed.
  if ! [ -x "$(command -v gsed)" ]; then
    echo "Error: 'gsed' is not installed." >&2
    echo "If you are using Homebrew, install with 'brew install gnu-sed'." >&2
    exit 1
  fi
  SED_CMD="gsed"
else
  SED_CMD="sed"
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

# You can ignore building manifests for some tasks by providing the SKIP_TASKS variable
# with the task name separated by a space, for example:
# SKIP_TASKS="git-clone init"

SKIP_TASKS=

warning_message="# WARNING: This is an auto generated file, do not modify this file directly"

main() {
    cd "$SCRIPT_DIR/.."
    local ret=0
    find task -maxdepth 3 -mindepth 3 -type f -name "*.yaml" | awk -F '/' '{ print $0, $2, $3, $4 }' | \
    while read -r task_path task_name task_version file_name
    do
        if [[ "$file_name" == "kustomization.yaml" ]]; then
          echo "Building task manifest for: $task_name/$task_version"
        else
          continue
        fi

        # Skip the tasks mentioned in SKIP_TASKS
        skipit=
        for tname in ${SKIP_TASKS};do
            [[ ${tname} == "${task_name}" ]] && skipit=True
        done
        [[ -n ${skipit} ]] && continue

        # Check if there is only one resource in the kustomization file and it is <task_name>.yaml
        resources=$(yq -r '.resources[]' "$task_path")
        if [[ "$resources" == "$task_name.yaml" ]]; then
          echo "Skip generating manifest for the task: $task_name/$task_version"
          continue
        fi
        if ! oc kustomize -o "task/$task_name/$task_version/$task_name.yaml" "task/$task_name/$task_version/"; then
            echo "failed to build task: $task_name" >&2
            ret=1
            continue
        fi
        # Add a warning message in the generated file
        ${SED_CMD} -i "1 i $warning_message" "task/$task_name/$task_version/$task_name.yaml"
    done

    exit "$ret"

}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    main "$@"
fi
