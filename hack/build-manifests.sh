#!/bin/bash -e

# To make the script work on linux and mac, use '${SED_CMD}' instead of 'sed'
# https://stackoverflow.com/a/4247319
if [[ "$OSTYPE" == "darwin"* ]]; then
  # Require gnu-sed.
  if ! [ -x "$(command -v gsed)" ]; then
    echo "Error: 'gsed' is not installed." >&2
    echo "If you are using Homebrew, install with 'brew install gnu-sed'." >&2
    exit 1
  fi
  SED_CMD=gsed
else
  SED_CMD=sed
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

# You can ignore building manifests for some tasks by providing the SKIP_TASKS variable
# with the task name separated by a space, for example:
# SKIP_TASKS="git-clone init"

SKIP_TASKS="generate-odcs-compose provision-env-with-ephemeral-namespace verify-signed-rpms"

# You can ignore building manifests for some pipelines by providing the SKIP_PIPELINES variable
# with the task name separated by a space, for example:
# SKIP_PIPELINES="rhtap gitops-pull-request-rhtap"

SKIP_PIPELINES="gitops-pull-request-rhtap"

warning_message="# WARNING: This is an auto generated file, do not modify this file directly"

main() {
    local dirs

    cd "$SCRIPT_DIR/.."
    local ret=0
    find task/*/*/*.yaml -maxdepth 0 | awk -F '/' '{ print $0, $2, $3, $4 }' | \
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

    find pipelines/*/*.yaml -maxdepth 0 | awk -F '/' '{ print $0, $2, $3 }' | \
    while read -r pipeline_path pipeline_name file_name
    do
        if [[ "$file_name" == "kustomization.yaml" ]]; then
          echo "Building pipeline manifest for: $pipeline_name"
        else
          continue
        fi
        
        # Skip the pipelines mentioned in SKIP_PIPELINES
        skipit=
        for pname in ${SKIP_PIPELINES};do
            [[ ${pname} == "${pipeline_name}" ]] && skipit=True
        done
        [[ -n ${skipit} ]] && continue
        
        # Check if there is only one resource in the kustomization file and it is <pipeline_name>.yaml
        resources=$(yq -r '.resources[]' "$pipeline_path")
        if [[ "$resources" == "$pipeline_name.yaml" ]]; then
          echo "Skip generating manifest for the pipeline: $pipeline_name"
          continue
        fi
        if ! oc kustomize -o "pipelines/$pipeline_name/$pipeline_name.yaml" "pipelines/$pipeline_name"; then
            echo "failed to build pipeline: $pipeline_name" >&2
            ret=1
            continue
        fi
        # Add a warning message in the generated file
        ${SED_CMD} -i "1 i $warning_message" "pipelines/$pipeline_name/$pipeline_name.yaml"
    done

    exit "$ret"

}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    main "$@"
fi
