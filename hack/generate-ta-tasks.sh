#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail
set -o posix

shopt -s globstar nullglob

HACK_DIR="$(realpath "$(dirname "${BASH_SOURCE[0]}")")"
ROOT_DIR="$(git rev-parse --show-toplevel)"
TASK_DIR="$(realpath "${ROOT_DIR}/task")"

if ! command -v tash &> /dev/null; then
  echo INFO: tash command is not available will download and use the latest version
  tash_dir="$(mktemp -d)"
  trap 'rm -rf ${tash_dir}' EXIT
  tash_url=https://github.com/enterprise-contract/hacks/releases/download/latest/tash
  echo INFO: downloading from ${tash_url} to "${tash_dir}"
  curl --no-progress-meter --location --output "${tash_dir}/tash" "${tash_url}"
  echo INFO: SHA256: "$(sha256sum "${tash_dir}/tash")"
  chmod +x "${tash_dir}/tash"
  tash() {
    "${tash_dir}/tash" "$@"
  }
fi

declare -i changes=0
emit() {
  if [ "${GITHUB_ACTIONS:-false}" == "true" ]; then
    printf "::error file=%s,line=1,col=0::%s\n" "$1" "$2"
  else
    printf "INFO: \033[1m%s\033[0m %s\n" "$1" "$2"
  fi
  changes=$((changes + 1))
}

msg="File is out of date and has been updated"
if [ "${GITHUB_ACTIONS:-false}" == "true" ]; then
  # shellcheck disable=SC2016
  msg='File is out of date, run `hack/generate-ta-tasks.sh` and include the updated file with your changes'
fi

cd "${TASK_DIR}"
for recipe_path in **/recipe.yaml; do
    task_path="${recipe_path%/recipe.yaml}/$(basename "${recipe_path%/*/*}").yaml"
    cat <<< "$(tash "${recipe_path}")" > "${task_path}"
    readme_path="${recipe_path%/recipe.yaml}/README.md"
    "${HACK_DIR}/generate-readme.sh" "${task_path}" > "${readme_path}"
    if ! git diff --quiet HEAD "${task_path}"; then
        emit "task/${task_path}" "${msg}"
    fi
    if ! git diff --quiet HEAD "${readme_path}"; then
        emit "task/${readme_path}" "${msg}"
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
