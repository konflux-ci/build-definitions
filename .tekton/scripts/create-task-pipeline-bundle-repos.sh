#!/usr/bin/bash

set -o errexit
set -o pipefail
set -o nounset

SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd "$SCRIPTDIR/../.."

CATALOG_NAMESPACES=(
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

    for quay_namespace in "${CATALOG_NAMESPACES[@]}"; do
        found=$(locate_bundle_repo "$quay_namespace" "$type" "$object")

        quay_repo=${type}-${object}

        # konflux-ci/tekton-catalog
        if [[ $quay_namespace = */* ]]; then
            # tekton-catalog/...
            quay_repo="${quay_namespace#*/}/$quay_repo"
            # konflux-ci
            quay_namespace=${quay_namespace%%/*}
        fi

        echo "Checking ${quay_namespace}/${quay_repo}, http code: ${found}"
        if [ "$found" != "200" ]; then
            echo "Missing $type bundle repo: ${quay_repo} in ${quay_namespace}, creating..."
            payload=$(
              jq -n \
                --arg namespace "$quay_namespace" \
                --arg repository "$quay_repo" \
                --arg visibility "public" \
                --arg description "" \
                '$ARGS.named'
            )
            if ! err_msg=$(curl --oauth2-bearer "${QUAY_TOKEN}" "https://quay.io/api/v1/repository" --data-binary "$payload" -H "Content-Type: application/json" -H "Accept: application/json" | jq -r '.error_message // empty');
            then
              echo "curl returned an error when creating the repository. See the error above."
              exit 1
            fi

            if [[ "$err_msg" == "Repository already exists" ]]; then
                echo "WARNING: repository creation failed, but the error message was '$err_msg'. Assuming that's fine."
            elif [[ -n "$err_msg" ]]; then
                echo "Quay returned an error when creating the repository: ${err_msg}"
                exit 1
            fi
        fi
    done
}

echo "Checking existence of task bundle repositories..."
echo

# tasks
while IFS= read -r -d '' task_dir
do
    if [ ! -f "$task_dir"/kustomization.yaml ]; then
      # expected structure: task/${name}/${version}/${name}.yaml
      task_name=$(basename "$(dirname "$task_dir")")
      task_name=$(yq < "$task_dir/$task_name.yaml" .metadata.name)
    else
      task_name=$(oc kustomize "$task_dir" | yq .metadata.name)
    fi

    locate_in_all_namespaces task "$task_name"
done < <(find task -mindepth 2 -maxdepth 2 -type d -print0)

echo
echo "Checking existence of pipeline bundle repositories..."
echo

# pipelines
pl_names=()
# Split by newlines into an array
while IFS=$'\n' read -r line;
  do pl_names+=("$line");
done <<<"$(oc kustomize pipelines/ | yq -o json '.metadata.name' | jq -r)"

# Currently, only one pipeline for core services CI
pl_names+=("$(oc kustomize pipelines/core-services/ | yq -o json '"core-services-" + .metadata.name' | jq -r)")
for pl_name in "${pl_names[@]}"; do
    echo "Checking pipeline: ${pl_name}"
    locate_in_all_namespaces pipeline "$pl_name"
done
