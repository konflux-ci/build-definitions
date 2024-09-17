#!/bin/bash
set -euo pipefail

SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

cd "${SCRIPTDIR}/../task-generator/remote"
go build -o /tmp/remote-generator main.go

for version in 0.1 0.2; do
    /tmp/remote-generator --buildah-task="${SCRIPTDIR}/../task/buildah/${version}/buildah.yaml" \
        --remote-task="${SCRIPTDIR}/../task/buildah-remote/${version}/buildah-remote.yaml" --task-version="$version"
    /tmp/remote-generator --buildah-task="${SCRIPTDIR}/../task/buildah-oci-ta/${version}/buildah-oci-ta.yaml" \
        --remote-task="${SCRIPTDIR}/../task/buildah-remote-oci-ta/${version}/buildah-remote-oci-ta.yaml" --task-version="$version"
done
