#!/usr/bin/env bash
set -o errexit
set -o nounset
set -o pipefail


# Function to remove the sha and digest from the image name
# from: quay.io/konflux-ci/task1:0.1-1234@sha256:5678 to quay.io/konflux-ci/task1:0.1
strip_image_tag() {
  sed 's/\(:[^-]*\).*/\1/' <<< "$1"
}

# helps with debugging
DATA_BUNDLE_REPO="${DATA_BUNDLE_REPO:-quay.io/konflux-ci/tekton-catalog/data-acceptable-bundles}"
mapfile -t BUNDLES < <(cat "$@")

SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
# File containing the list of images
OUTPUT_TASK_BUNDLE_LIST="${OUTPUT_TASK_BUNDLE_LIST-${SCRIPTDIR}/../task-bundle-list}"
for i in "${!BUNDLES[@]}"; do
    original_line="${BUNDLES[$i]}"
    modified_line=$(strip_image_tag "$original_line")
    BUNDLES[$i]="$modified_line"
    echo "$original_line,$modified_line" >> "$OUTPUT_TASK_BUNDLE_LIST"
done

# store a list of changed task files
task_records=()
# loop over all changed files
for path in $(git log -m -1 --name-only --pretty="format:" "${REVISION}"); do
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

if [ ${#task_records[@]} -gt 0 ]; then
    echo "Tasks to be added:"
    printf '%s\n' "${task_records[@]}"
fi

if [ ${#BUNDLES[@]} -gt 0 ]; then
    echo "Bundles to be added:"
    printf '%s\n' "${BUNDLES[@]}"
fi

# The OPA data bundle is tagged with the current timestamp. This has two main
# advantages. First, it prevents the image from accidentally not having any tags,
# and getting garbage collected. Second, it helps us create a timeline of the
# changes done to the data over time.
DATA_BUNDLE_TAG=${DATA_BUNDLE_TAG:-$(date '+%s')}

# task_records can be empty if a task wasn't changed
TASK_PARAM=()
if [ ${#task_records[@]} -gt 0 ]; then
  mapfile -t -d ' ' TASK_PARAM < <(printf -- '--git=%s ' "${task_records[@]}")
fi
mapfile -t -d ' ' BUNDLES_PARAM < <(printf -- '--bundle=%s ' "${BUNDLES[@]}")

PARAMS=("${TASK_PARAM[@]}" "${BUNDLES_PARAM[@]}")
ec track bundle --debug \
    --input "oci:${DATA_BUNDLE_REPO}:latest" \
    --output "oci:${DATA_BUNDLE_REPO}:${DATA_BUNDLE_TAG}" \
    --timeout "15m0s" \
    --freshen \
    --prune \
    "${PARAMS[@]}"

# To facilitate usage in some contexts, tag the image with the floating "latest" tag.
skopeo copy "docker://${DATA_BUNDLE_REPO}:${DATA_BUNDLE_TAG}" "docker://${DATA_BUNDLE_REPO}:latest"
