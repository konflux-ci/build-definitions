#!/bin/bash
set -o errexit -o nounset -o pipefail

# <TEMPLATED FILE!>
# This file comes from the templates at https://github.com/konflux-ci/task-repo-shared-ci.
# Please consider sending a PR upstream instead of editing the file directly.
# See the SHARED-CI.md document in this repo for more details.

get_checkton_image_based_on_action_version() {
    sed -nE \
        's;^\s*uses: (.*)/checkton.*(v[0-9]\S*);ghcr.io/\1/checkton:\2;p' \
        .github/workflows/checkton.yaml
}

mapfile -t checkton_env_vars < <(
    env CHECKTON_FIND_COPIES_HARDER="${CHECKTON_FIND_COPIES_HARDER:-true}" | grep '^CHECKTON_'
)
CHECKTON_IMAGE=${CHECKTON_IMAGE:-$(get_checkton_image_based_on_action_version)}

{
    echo "Checkton image: $CHECKTON_IMAGE"

    echo "CHECKTON_* variables:"
    printf "  %s\n" "${checkton_env_vars[@]}"
} >&2


if command -v getenforce >/dev/null && [[ "$(getenforce)" == Enforcing ]]; then
    z=":z"
else
    z=""
fi

mapfile -t env_flags < <(printf -- "--env=%s\n" "${checkton_env_vars[@]}")

podman run --rm --tty -v "$PWD:/code${z}" -w /code "${env_flags[@]}" "$CHECKTON_IMAGE"
