#!/usr/bin/env bash
set -euo pipefail

# helps with debugging
DATA_BUNDLE_REPO="${DATA_BUNDLE_REPO:-quay.io/redhat-appstudio-tekton-catalog/data-acceptable-bundles}"
BUNDLES=${BUNDLES:-()}

# store a list of changed task files
task_records=()
# loop over all changed files
for path in $(git diff-tree -c --name-only --no-commit-id -r ${REVISION}); do
    # check that the file modified is the task file
    if [[ "${path}" == task/*/*/*.yaml ]]; then
    IFS='/' read -r -a path_array <<< "${path}"
    dir_name_after_task="${path_array[1]}"
    file_name=$(basename "${path_array[-1]}" ".yaml")

    if [[ "${dir_name_after_task}" == "${file_name}" ]]; then
        # GIT_URL is the repo_url from PAC (https://hostname/org/repo)
        task_records+=("git+${GIT_URL}.git//${path}@${REVISION}")
    fi
    fi
done

echo "${task_records[@]}"

touch ${BUNDLES[@]}
echo "Bundles to be added:"
cat ${BUNDLES[@]}

# The OPA data bundle is tagged with the current timestamp. This has two main
# advantages. First, it prevents the image from accidentally not having any tags,
# and getting garbage collected. Second, it helps us create a timeline of the
# changes done to the data over time.
TAG="$(date '+%s')"

# task_records can be empty if a task wasn't changed
TASK_PARAM=()
if [ "${#task_records[@]}" -gt 0 ]; then
    TASK_PARAM=($(printf "%s\n" "${task_records[@]}" | awk '{ print "--git=" $0 }'))
fi

BUNDLES_PARAM=($(cat ${BUNDLES[@]} | awk '{ print "--bundle=" $0 }'))

PARAMS=("${TASK_PARAM[@]}" "${BUNDLES_PARAM[@]}")
ec track bundle --debug \
    --input "oci:${DATA_BUNDLE_REPO}:latest" \
    --output "oci:${DATA_BUNDLE_REPO}:${TAG}" \
    --timeout "15m0s" \
    --freshen \
    --prune \
    ${PARAMS[@]}

# To facilitate usage in some contexts, tag the image with the floating "latest" tag.
skopeo copy "docker://${DATA_BUNDLE_REPO}:${TAG}" "docker://${DATA_BUNDLE_REPO}:latest"
