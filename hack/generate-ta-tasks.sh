#!/usr/bin/env bash

# <TEMPLATED FILE!>
# This file comes from the templates at https://github.com/konflux-ci/task-repo-shared-ci.
# Please consider sending a PR upstream instead of editing the file directly.
# See the SHARED-CI.md document in this repo for more details.

set -o errexit
set -o errtrace
set -o nounset
set -o pipefail
set -o posix

shopt -s globstar nullglob

command -v go &> /dev/null || { echo Please install golang to run this tool; exit 1; }
[[ "$(go env GOVERSION)" == @(go1|go1.[1-9]+(|.*|rc*|beta*)|go1.1[0-9]+(|.*|rc*|beta*)|go1.20*) ]] && { echo Please install golang 1.21.0 or newer; exit 1; }

HACK_DIR="$(realpath "$(dirname "${BASH_SOURCE[0]}")")"
ROOT_DIR="$(git rev-parse --show-toplevel)"
TASK_DIR="$(realpath "${ROOT_DIR}/task")"
: "${TRUSTED_ARTIFACTS=github.com/konflux-ci/build-definitions/task-generator/trusted-artifacts@latest}"

tashdir="$(mktemp --dry-run)"
if [[ -d "${TRUSTED_ARTIFACTS}" ]]; then
    tashbin=${tashdir}/trusted-artifacts
    GOTOOLCHAIN=auto GOSUMDB=sum.golang.org go build -C "${TRUSTED_ARTIFACTS}" -o "${tashbin}"
else
    GOTOOLCHAIN=auto GOSUMDB=sum.golang.org GOBIN="$tashdir" go install "${TRUSTED_ARTIFACTS}"
    bin=("${tashdir}"/*)
    if [[ ${#bin[@]} -ne 1 ]]; then
      echo "Expected exactly one executable, got ${#bin[@]}: ${bin[*]}" >&2
      exit 1
    fi
    tashbin=${bin[0]}
fi
trap 'rm -r "${tashdir}"' EXIT

tash() {
  "${tashbin}" "$@"
}

declare -i changes=0
emit() {
  local file=$1
  local msg=$2
  if [ "${GITHUB_ACTIONS:-false}" == "true" ]; then
    printf "::error file=%s,line=1,col=0::%s\n" "$file" "$msg"
  else
    printf "INFO: \033[1m%s\033[0m %s\n" "$file" "$msg"
  fi
  changes=$((changes + 1))
}

msg="File is out of date and has been updated"
if [ "${GITHUB_ACTIONS:-false}" == "true" ]; then
  # shellcheck disable=SC2016
  msg='File is out of date, run `hack/generate-ta-tasks.sh` and include the updated file with your changes.'
fi

cd "${TASK_DIR}"
for recipe_path in **/recipe.yaml; do
    task_path="${recipe_path%/recipe.yaml}/$(basename "${recipe_path%/*/*}").yaml"
    sponge=$(tash "${TASK_DIR}/${recipe_path}")
    echo "${sponge}" > "${task_path}"
    if ! git diff --quiet HEAD "${task_path}"; then
        emit "task/${task_path}" "${msg}"
    fi
done

if [[ ${changes} -gt 0 ]]; then
  if [ "${GITHUB_ACTIONS:-false}" == "true" ]; then
    # shellcheck disable=SC2016
    echo '::notice title=Apply the attached patch::Download the attached `ta.patch` file and run `git apply ta.patch`'
    git diff -u | tee "${ROOT_DIR}/ta.patch"
    exit 1
  else
    printf "INFO: \033[1mMake sure to include the regenerated files in your changeset\033[0m\n"
  fi
fi
