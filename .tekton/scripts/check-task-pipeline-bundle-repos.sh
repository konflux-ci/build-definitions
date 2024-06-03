#!/usr/bin/bash

set -o errexit
set -o pipefail
set -o nounset

SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd "$SCRIPTDIR/../.."

CATALOG_NAMESPACES=(
    redhat-appstudio-tekton-catalog
    konflux-ci/tekton-catalog
)

locate_bundle_repo() {
    local -r quay_namespace="$1"
    local -r type="$2"
    local -r object="$3"

    curl -I -s -L -w "%{http_code}\n" -o /dev/null "https://quay.io/v2/${quay_namespace}/${type}-${object}/tags/list"
}

locate_in_all_namespaces() {
    local -r type="$1"
    local -r object="$2"

    local rc=0

    for quay_namespace in "${CATALOG_NAMESPACES[@]}"; do
        found=$(locate_bundle_repo "$quay_namespace" "$type" "$object")
        if [ "$found" != "200" ]; then
            echo "Missing $type bundle repo: ${quay_namespace}/${type}-${object}"
            rc=1
        fi
    done

    return "$rc"
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

    if ! locate_in_all_namespaces task "$task_name"; then
        has_missing_repo=yes
    fi
done

# pipelines
pl_names=($(oc kustomize pipelines/ | oc apply --dry-run=client -f - -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}'))
# Currently, only one pipeline for core services CI
pl_names+=($(oc kustomize pipelines/core-services/ | oc apply --dry-run=client -f - -o jsonpath='{"core-services-"}{.metadata.name}'))
for pl_name in ${pl_names[@]}; do
    if ! locate_in_all_namespaces pipeline "$pl_name"; then
        has_missing_repo=yes
    fi
done

if [ -n "$has_missing_repo" ]; then
    echo "Please contact Build team - #forum-stonesoup-build that the missing repos should be created in:"
    echo "- https://quay.io/organization/redhat-appstudio-tekton-catalog"
    echo "- https://quay.io/organization/konflux-ci"
    exit 1
else
    echo "Done"
fi
