#!/usr/bin/env bash

set -o errexit
set -o errtrace
set -o nounset
set -o pipefail
set -o posix

shopt -s globstar nullglob

HACK_DIR="$(realpath "$(dirname "${BASH_SOURCE[0]}")")"
ROOT_DIR="$(git rev-parse --show-toplevel)"
TASK_DIR="$(realpath "${ROOT_DIR}/task")"

# sast-coverity-check of version 0.2 and newer uses kustomize to build the task
# definition from the buildah task and a locally maintained patch.yaml
for dir in "${TASK_DIR}/sast-coverity-check"/0.[2-9]; do (
    cd "$dir" && kustomize build > sast-coverity-check.yaml
) done
