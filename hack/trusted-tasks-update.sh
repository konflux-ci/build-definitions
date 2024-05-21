#!/usr/bin/env bash
# Resolves all tasks from the `/task` directory of this repository and any Task
# bundles in the `$QUAY_NAMESPACE` quay.io namespace (defaults to
# `redhat-appstudio-tekton-catalog`) and runs `ec track bundle` with those git
# and image references in order to catalogue the latest versions in the trusted
# tasks list in `$INPUT_IMAGE` written to `$OUTPUT_IMAGE` (both default to
# `quay.io/redhat-appstudio-tekton-catalog/data-acceptable-bundles:latest`).
#
# By default both git and image references are collected, what is collected can
# be controlled by `$COLLECT` which can be set to `git` or `oci`
#
# Parameters via environment variables:
# COLLECT        - can be set to `oci` or `git` (defaults to both), what to
#                  resolve
# INPUT_IMAGE    - Conftest OCI bundle containing the trusted tasks list, defaults
#                  to:
#                  `quay.io/redhat-appstudio-tekton-catalog/data-acceptable-bundles:latest`
# OUTPUT_IMAGE   - Conftest OCI bundle to write the trusted task list to, defaults
#                  to `$INPUT_IMAGE`
# QUAY_NAMESPACE - Quay namespace to query for Task bundles (defaults to
#                  `redhat-appstudio-tekton-catalog`)

set -o errexit
set -o nounset
set -o pipefail

mapfile -td ' ' COLLECT < <(echo -n "${COLLECT:-git oci}")
INPUT_IMAGE=${INPUT_IMAGE:-quay.io/redhat-appstudio-tekton-catalog/data-acceptable-bundles:latest}
OUTPUT_IMAGE=${OUTPUT_IMAGE:-$INPUT_IMAGE}
GIT_REPOSITORY=git+https://github.com/konflux-ci/build-definitions.git
QUAY_NAMESPACE=${QUAY_NAMESPACE:-redhat-appstudio-tekton-catalog}

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
      for repository in $(
        curl -sSL "https://quay.io/api/v1/repository?namespace=${QUAY_NAMESPACE}&public=true" -H 'Accept: application/json' |
          jq -r '.repositories.[].name | select(startswith("task-")) | "quay.io/'"${QUAY_NAMESPACE}"'/\(.)"'
      ); do
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
  "${oci_params[@]}"
