#!/bin/bash -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

main() {

    "${SCRIPT_DIR}"/build-manifests.sh
    if [[ $(git status --porcelain) ]]; then
        git diff --exit-code >&2 || {
            echo "Did you forget to build the manifests locally?" >&2;
            echo "Please run ./hack/build-manifests.sh and update your PR" >&2;
            echo "Or run ./hack/generate-everything.sh to run all the generators at once." >&2;
            exit 1;
        }
    fi
    echo "changes are up to date" >&2
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    main "$@"
fi
