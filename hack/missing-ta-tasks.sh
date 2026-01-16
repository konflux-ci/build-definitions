#!/usr/bin/env bash

# <TEMPLATED FILE!>
# This file comes from the templates at https://github.com/konflux-ci/task-repo-shared-ci.
# Please consider sending a PR upstream instead of editing the file directly.
# See the SHARED-CI.md document in this repo for more details.

set -o errexit
set -o nounset
set -o pipefail
shopt -s globstar

git_root=$(git rev-parse --show-toplevel)

emit() {
  kind="$1"
  file="$2"
  msg="$3"
  if [ "${GITHUB_ACTIONS:-false}" == "true" ]; then
    printf "::${kind} file=%s,line=1,col=0::%s\n" "${file}" "${msg}"
  else
    printf "${kind@U}: \033[1m%s\033[0m %s\n" "${file}" "${msg}"
  fi
}

{
  cd "${git_root}"

  IGNORE_PATHS=()
  IGNORE_WORKSPACES=()
  for ignorefile in .github/.ta-ignore.yaml .ta-ignore.yaml; do
    if [[ -e "$ignorefile" ]]; then
      echo "Using ignorefile: $ignorefile"

      mapfile -t IGNORE_PATHS < <(yq -r '.paths[]?' "$ignorefile")
      mapfile -t IGNORE_WORKSPACES < <(yq -r '.workspaces[]?' "$ignorefile")

      echo "Ignored paths: ${IGNORE_PATHS[*]}"
      echo "Ignored workspaces: ${IGNORE_WORKSPACES[*]}"
      break
    fi
  done

  missing=0
  for task in task/**/*.yaml; do
      # archived tasks need to be skipped
      if [[  $(realpath "${git_root}/${task}") != "${git_root}/${task}" ]]; then
          echo "skipping $task (is a symlink) ..."
          continue
      fi
      task_file="${task}"
      case "${task}" in
          */kustomization.yaml | */recipe.yaml | */patch.yaml)
              continue
              ;;
      esac

      for pattern in "${IGNORE_PATHS[@]}"; do
        # shellcheck disable=SC2053  # glob matching is intentional here
        if [[ "${task}" == ${pattern} ]]; then
          continue 2
        fi
      done

      # we are looking at a Task
      yq -e '.kind != "Task"' "${task_file}" > /dev/null 2>&1 && continue

      is_deprecated=$(yq '.metadata?.annotations?["build.appstudio.redhat.com/expires-on"] != null' "${task_file}")
      if [[ "${is_deprecated}" == true ]]; then
          echo "skipping ${task} (is deprecated)"
          continue
      fi

      # path elements of the task file path
      readarray -d / paths <<< "${task}"
      # PVC non-optional workspaces used
      workspaces=$(yq -o json '[.spec.workspaces[].name]' "${task_file}")
      disallowed_workspaces=$(
        jq -nc '$workspaces - $ARGS.positional' --argjson workspaces "$workspaces" --args "${IGNORE_WORKSPACES[@]}"
      )

      # is the task using a workspace(s) to share files?
      [[ "$disallowed_workspaces" == '[]' ]] && continue

      # is there a newer version of the task
      base_task_path=("${paths[@]}")
      unset 'base_task_path[-1]'
      version="${base_task_path[-1]/\/}"
      unset 'base_task_path[-1]'
      for dir in $(IFS=''; echo "${base_task_path[*]}*"); do
          [[ ! -d "${dir}" ]] && continue
          [[ "${version}" < "${dir/*\/}" ]] && continue 2
      done

      # there is no Trusted Artifacts variant of the task
      unset 'paths[-1]'
      paths[-2]="${paths[-2]%/}-oci-ta/"
      ta_dir="$(IFS=''; echo "${paths[*]}")"
      if [[ ! -d "${ta_dir}" ]]; then
          emit error "${task}" "Task is using a workspace(s): ${disallowed_workspaces}, to share data and needs a corresponding Trusted Artifacts Task variant in ${ta_dir}"
          missing=$((missing + 1))
      fi
  done

  if [[ ${missing} -gt 0 ]]; then
    if [ "${GITHUB_ACTIONS:-false}" == "true" ]; then
      echo '::notice title=Missing Trusted Artifact Task Variant::Found Tasks that share data via workspaces without a corresponding Trusted Artifacts Variant. Please create the Trusted Artifacts Variant of the Task as well'
      exit 1
    fi
  fi
}
