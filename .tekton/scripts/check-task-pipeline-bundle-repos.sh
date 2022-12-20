#!/usr/bin/bash -e

SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd "$SCRIPTDIR/../.."

QUAY_ORG=redhat-appstudio-tekton-catalog

locate_bundle_repo() {
    local -r repo_name=$1
    curl -I -s -L -w "%{http_code}\n" -o /dev/null "https://quay.io/api/v1/repository/${QUAY_ORG}/${repo_name}"
}

has_missing_repo=

echo "Checking existence of task and pipeline bundle repositories ..."

# tasks
for task_file in task/*/*/*.yaml; do
    task_name=$(oc apply --dry-run=client -f "$task_file" -o jsonpath='{.metadata.name}')
    found=$(locate_bundle_repo "task-$task_name")
    if [ "$found" != "200" ]; then
        echo "Missing task bundle repo: task-$task_name"
        has_missing_repo=yes
    fi
done

# pipelines
for pl_name in $(oc kustomize pipelines/ | oc apply --dry-run=client -f - -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}'); do
    found=$(locate_bundle_repo "pipeline-$pl_name")
    if [ "$found" != "200" ]; then
        echo "Missing pipeline bundle repo: pipeline-$pl_name"
        has_missing_repo=yes
    fi
done

if [ -n "$has_missing_repo" ]; then
    exit 1
else
    echo "Done"
fi
