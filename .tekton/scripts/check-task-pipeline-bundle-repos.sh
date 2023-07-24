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

    curl -I -s -L -w "%{http_code}\n" -o /dev/null "https://quay.io/v2/${QUAY_ORG}/${type}-${object}/tags/list"
}

has_missing_repo=

echo "Checking existence of task and pipeline bundle repositories ..."

# tasks
for task_dir in $(find task/*/*/ -maxdepth 0 -type d); do
    if [ ! -f $task_dir/kustomization.yaml ]; then
      task_name=$(oc apply --dry-run=client -f "$task_dir/*.yaml" -o jsonpath='{.metadata.name}')
    else
      task_name=$(oc apply --dry-run=client -k "$task_dir" -o jsonpath='{.metadata.name}')
    fi
    found=$(locate_bundle_repo task "$task_name")
    if [ "$found" != "200" ]; then
        echo "Missing task bundle repo: task-$task_name"
        has_missing_repo=yes
    fi
done

# pipelines
pl_names=($(oc kustomize pipelines/ | oc apply --dry-run=client -f - -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}'))
# Currently, only one pipeline for core services CI
pl_names+=($(oc kustomize pipelines/core-services/ | oc apply --dry-run=client -f - -o jsonpath='{"core-services-"}{.metadata.name}'))
for pl_name in ${pl_names[@]}; do
    found=$(locate_bundle_repo pipeline "$pl_name")
    if [ "$found" != "200" ]; then
        echo "Missing pipeline bundle repo: pipeline-$pl_name"
        has_missing_repo=yes
    fi
done

if [ -n "$has_missing_repo" ]; then
    echo "Please contact Build team - #forum-stonesoup-build that the missing repos should be created in https://quay.io/organization/redhat-appstudio-tekton-catalog"
    exit 1
else
    echo "Done"
fi
