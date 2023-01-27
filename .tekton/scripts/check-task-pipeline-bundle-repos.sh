#!/usr/bin/bash

set -o errexit
set -o pipefail
set -o nounset

SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd "$SCRIPTDIR/../.."

QUAY_ORG=redhat-appstudio-tekton-catalog

locate_bundle_repo() {
    local -r type="$1"
    local -r object="$2"
    local -r version="${3}"

    if [ "${PULL_REQUEST:-0}" -ne 1 ]; then
        curl -I -s -L -w "%{http_code}\n" -o /dev/null "https://quay.io/v2/${QUAY_ORG}/${type}-${object}/manifests/${version}"
    else
        curl -I -s -L -w "%{http_code}\n" -o /dev/null "https://quay.io/v2/${QUAY_ORG}/pull-request-builds/manifests/${object}-${version}"
    fi
}

has_missing_repo=

echo "Checking existence of task and pipeline bundle repositories ..."

# tasks
for task_file in task/*/*/*.yaml; do
    task_name=$(oc apply --dry-run=client -f "$task_file" -o jsonpath='{.metadata.name}')
    dir=${task_file%/*}
    version="${dir##*/}-$(git log -n 1 --pretty=format:%H -- "${task_file}")"
    found=$(locate_bundle_repo task "$task_name" "${version}")
    if [ "$found" != "200" ]; then
        echo "Missing task bundle repo: task-$task_name"
        has_missing_repo=yes
    fi
done

# pipelines
version="$(git rev-parse HEAD)"
for pl_name in $(oc kustomize pipelines/ | oc apply --dry-run=client -f - -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}'); do
    found=$(locate_bundle_repo pipeline "$pl_name" "${version}")
    if [ "$found" != "200" ]; then
        echo "Missing pipeline bundle repo: pipeline-$pl_name ${version}"
        has_missing_repo=yes
    fi
done

if [ -n "$has_missing_repo" ]; then
    exit 1
else
    echo "Done"
fi
