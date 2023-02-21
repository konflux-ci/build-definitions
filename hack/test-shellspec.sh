#!/bin/env bash

set -o errexit
set -o pipefail
set -o nounset

ROOT="$(git rev-parse --show-toplevel)"

# Run tests only for changed
INCREMENTAL=${INCREMENTAL:-1}

readarray SPEC_DIRS < <(find "${ROOT}" -name spec -type d -print0)

REF=main
if ! git rev-parse --verify main 2>/dev/null; then
    REF=$(openssl rand -base64 12)
fi
git fetch origin "main:${REF}"
readarray CHANGED_FILES < <(git diff .."${REF}" --name-only; git status --porcelain=v1 | cut -c 4-)

for CHANGED in "${CHANGED_FILES[@]}"; do
    CHANGED_DIR="${ROOT}/$(dirname "${CHANGED}")"
    for SPEC_DIR in "${SPEC_DIRS[@]}"; do
        # If the changed file is within the `spec` directory or the directory
        # above it
        if [[ "${CHANGED_DIR}" == "${SPEC_DIR}" || "${CHANGED_DIR}/spec" == "${SPEC_DIR}" ]]; then
            SPEC_DIRS=("${SPEC_DIRS[@]/${SPEC_DIR}}")
            [[ -n "${GITHUB_ACTIONS:-}" ]] && echo "::group::Shellspec test in ${SPEC_DIR}"
            echo -e "Detected changes in \033[1m${CHANGED_DIR}\033[0m, running tests"
            PARAMS=(--chdir "${SPEC_DIR}" --shell /usr/bin/bash)
            [[ -n "${GITHUB_ACTIONS:-}" ]] && PARAMS+=(--format github -I "${ROOT}/hack/shellspec")
            if ! command -v shellspec &> /dev/null; then
                curl -fsSL https://git.io/shellspec | sh -s -- --yes
            fi
            shellspec "${PARAMS[@]}"
            [[ -n "${GITHUB_ACTIONS:-}" ]] && echo '::endgroup::'
        fi
    done
done
