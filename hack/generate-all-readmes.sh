#!/usr/bin/env bash

# This script generates a README.md for every Tekton Task in the repository
# by finding the task YAML file that matches its parent directory name.

set -o errexit -o nounset -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${SCRIPT_DIR}/.."

echo "INFO: Generating READMEs for all tasks..."

# The '-type d' flag ensures that symlinks are ignored
# so that we do not update the archived-tasks folder
find task -type d | while read -r version_dir; do
    task_name=$(basename "$(dirname "$version_dir")")
    task_path="${version_dir}/${task_name}.yaml"

    if [ -f "${task_path}" ]; then
        readme_path="${version_dir}/README.md"

        echo "  - Generating ${readme_path}"
        "${SCRIPT_DIR}/generate-readme.sh" "${task_path}" "${readme_path}"
    fi
done

echo "INFO: Finished generating all READMEs."
