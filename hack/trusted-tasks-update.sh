#!/usr/bin/env bash
# Resolves all tasks from the `/task` directory of this repository and any Task
# bundles in the `$QUAY_NAMESPACES` quay.io namespaces. Runs `ec track bundle`
# with those git and image references in order to catalogue the latest versions
# in the trusted tasks list in `$INPUT_IMAGE` written to `$OUTPUT_IMAGE` (both
# default to `quay.io/konflux-ci/tekton-catalog/data-acceptable-bundles:latest`).
#
# By default both git and image references are collected, what is collected can
# be controlled by `$COLLECT` which can be set to `git` or `oci`
#
# Parameters via environment variables:
# COLLECT         - can be set to `oci` or `git` (defaults to both), what to
#                   resolve
# INPUT_IMAGE     - Conftest OCI bundle containing the trusted tasks list, defaults
#                   to:
#                   `quay.io/konflux-ci/tekton-catalog/data-acceptable-bundles:latest`
# OUTPUT_IMAGE    - Conftest OCI bundle to write the trusted task list to, defaults
#                   to `$INPUT_IMAGE`
# QUAY_NAMESPACES - Quay namespaces to query for Task bundles (defaults to
#                   `redhat-appstudio-tekton-catalog konflux-ci/tekton-catalog`)

set -o errexit
set -o nounset
set -o pipefail

mapfile -td ' ' COLLECT < <(echo -n "${COLLECT:-git oci}")
mapfile -td ' ' QUAY_NAMESPACES < <(
    echo -n "${QUAY_NAMESPACES:-"redhat-appstudio-tekton-catalog konflux-ci/tekton-catalog"}"
)

INPUT_IMAGE=${INPUT_IMAGE:-quay.io/konflux-ci/tekton-catalog/data-acceptable-bundles:latest}
OUTPUT_IMAGE=${OUTPUT_IMAGE:-$INPUT_IMAGE}
GIT_REPOSITORY=git+https://github.com/konflux-ci/build-definitions.git

function list_tasks() {
    local full_namespace=$1
    # The Quay API only supports filtering by e.g. "konflux-ci", not by "konflux-ci/tekton-catalog"
    local toplevel_namespace=${full_namespace%%/*}

    curl -sSL "https://quay.io/api/v1/repository?namespace=${toplevel_namespace}&public=true" -H 'Accept: application/json' |
        jq --arg full_namespace "$full_namespace" -r '
            .repositories[]
            | "\(.namespace)/\(.name)"
            | select(test("^\($full_namespace)/task-[^/]*$"))
            | "quay.io/\(.)"
        '
}

function list_tasks_in_all_namespaces() {
    for namespace in "${QUAY_NAMESPACES[@]}"; do
        list_tasks "$namespace"
    done
}

HACK_DIR="$(dirname "${BASH_SOURCE[0]}")"

git_params=()
oci_params=()
for c in "${COLLECT[@]}"; do
  case "${c}" in
    git)
      echo -n Resolving git Tasks
      for task_dir in "${HACK_DIR}"/../task/*/*; do
        [ ! -d "${task_dir}" ] && continue
        [ -f "${task_dir}/kustomization.yaml" ] && continue
        mapfile -td '/' dirparts < <(echo "${task_dir}")
        task_file="${task_dir}/${dirparts[-2]}.yaml"
        [ ! -f "${task_file}" ] && continue

        task_git_url=${GIT_REPOSITORY}//${task_file/#*task/task}
        git_params+=("--git=${task_git_url}")
        echo -n .
      done
      echo
      echo Collected git parameters:
      printf "%s\n" "${git_params[@]}"
      ;;
    oci)
      echo -n Resolving OCI Tasks bundles
      for repository in $(list_tasks_in_all_namespaces); do
        mapfile -t refs < <(
          skopeo list-tags docker://"${repository}" |
            jq --arg repository "${repository}" -r '.Tags[] | select(test("^(\\d+)(\\.\\d)*$")) | "\($repository):\(.)"'
        )
        for ref in "${refs[@]}"; do
          oci_params+=("--bundle=${ref}")
        done
        echo -n .
      done
      echo
      echo Collected OCI parameters:
      printf "%s\n" "${oci_params[@]}"
  esac
done

echo Running:
PS4=''
set -x
ec track bundle \
  --freshen \
  --input "oci:${INPUT_IMAGE}" \
  --output "oci:${OUTPUT_IMAGE}" \
  "${git_params[@]}" \
  "${oci_params[@]}" \
  --timeout 0
