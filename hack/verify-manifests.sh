#!/bin/bash -e

# <TEMPLATED FILE!>
# This file comes from the templates at https://github.com/konflux-ci/task-repo-shared-ci.
# Please consider sending a PR upstream instead of editing the file directly.
# See the SHARED-CI.md document in this repo for more details.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

main() {

    "${SCRIPT_DIR}"/build-manifests.sh
    if [[ $(git status --porcelain) ]]; then
        git diff --exit-code >&2 || {
            echo "Did you forget to build the manifests locally?" >&2;
            echo "Please run ./hack/build-manifests.sh and update your PR" >&2;
            exit 1;
        }
    fi
    echo "changes are up to date" >&2
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    main "$@"
fi
