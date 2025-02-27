#!/bin/bash
set -o errexit -o nounset -o pipefail -o xtrace

SCRIPTDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
cd "$SCRIPTDIR/.."

# These 3 need to run in this order. Not for any logical reasons, but simply
# because of the current state of dependence between the generated tasks
# and the sources they are generated from.
hack/build-manifests.sh
hack/generate-ta-tasks.sh
hack/generate-buildah-remote.sh

hack/generate-pipelines-readme.py

hack/update_renovate_json_based_on_codeowners.py -o renovate.json
