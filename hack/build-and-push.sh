#!/bin/bash -e

QUAY_ORG=redhat-appstudio-tekton-catalog
# local dev build script
SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
WORKDIR=$(mktemp -d --suffix "-$(basename "${BASH_SOURCE[0]}" .sh)")

# Helper function to record the image reference from the output of
# the "tkn bundle push" command into a given file.
# Params:
#   1. Image reference including the tag
#   2. Output file
# Returns the piped in standard input followed by a line containing the image
# reference including tag and digest
function save_ref() {
    local output
    output="$(< /dev/stdin)"
    echo "${output}"
    local digest
    digest="$(echo "${output}" | grep -Po '@\K(sha256:[a-f0-9]*)')"

    local tagRef
    tagRef="$1"
    local refFile
    refFile="$2"
    echo "${tagRef}@${digest}" >> "${refFile}"
    echo "Created:"
    echo "${tagRef}@${digest}"
}

if [[ $(uname) = Darwin ]]; then
    CSPLIT_CMD="gcsplit"
else
    CSPLIT_CMD="csplit"
fi

if [ -z "$MY_QUAY_USER" ]; then
    echo "MY_QUAY_USER is not set, skip this build."
    exit 0
fi
if [ -z "$BUILD_TAG" ]; then
    if [ "$MY_QUAY_USER" == "$QUAY_ORG" ]; then
        echo "'${QUAY_ORG}' repo is used, define BUILD_TAG"
        exit 1
    else
        # At the step of converting tasks to Tekton catalog, this is only
        # applied to non-task resources.
        BUILD_TAG=$(date +"%Y-%m-%d-%H%M%S")
        echo "BUILD_TAG is not defined, using $BUILD_TAG"
    fi
fi

# Specify TEST_REPO_NAME env var if you want to push all images to a single quay repository
# (This method is used in PR testing)
: "${TEST_REPO_NAME:=}"

APPSTUDIO_UTILS_IMG="quay.io/$MY_QUAY_USER/${TEST_REPO_NAME:-appstudio-utils}:${TEST_REPO_NAME:+build-definitions-utils-}$BUILD_TAG"

OUTPUT_TASK_BUNDLE_LIST="${OUTPUT_TASK_BUNDLE_LIST-${SCRIPTDIR}/../task-bundle-list}"
OUTPUT_PIPELINE_BUNDLE_LIST="${OUTPUT_PIPELINE_BUNDLE_LIST-${SCRIPTDIR}/../pipeline-bundle-list}"
rm -f "${OUTPUT_TASK_BUNDLE_LIST}" "${OUTPUT_PIPELINE_BUNDLE_LIST}"

# Build appstudio-utils image
if [ "$SKIP_BUILD" == "" ]; then
    echo "Using $MY_QUAY_USER to push results "
    docker build -t "$APPSTUDIO_UTILS_IMG" "$SCRIPTDIR/../appstudio-utils/"
    docker push "$APPSTUDIO_UTILS_IMG"
fi

prepared_pipelines_dir=$(mktemp -d -p "$WORKDIR" pipelines.XXXXXXXX)
defined_pipelines_dirs=(
    "$SCRIPTDIR/../pipelines/base"
    "$SCRIPTDIR/../pipelines/hacbs"
    "$SCRIPTDIR/../pipelines/hacbs-core-service"
)
for dir_name in ${defined_pipelines_dirs[@]}
do
    output_dir="$prepared_pipelines_dir/$(basename "$dir_name")"
    mkdir "$output_dir"
    oc kustomize --output "$output_dir" "$dir_name"
done

# Build tasks
(
cd "$SCRIPTDIR/.."
find task/*/*/*.yaml | awk -F '/' '{ print $0, $2, $3 }' | \
while read -r task_file task_name task_version
do
    prepared_task_file="${WORKDIR}/$(basename "$task_file" .yaml)-${task_version}.yaml"
    cp "$task_file" "$prepared_task_file"
    yq e -i ".spec.steps[] |= select(.image == \"appstudio-utils\").image = \"${APPSTUDIO_UTILS_IMG}\"" "$prepared_task_file"

    task_bundle=quay.io/$MY_QUAY_USER/${TEST_REPO_NAME:-task-${task_name}}:${TEST_REPO_NAME:+${task_name}-}${task_version}
    output=$(tkn bundle push -f "$prepared_task_file" "$task_bundle" | save_ref "$task_bundle" "$OUTPUT_TASK_BUNDLE_LIST")
    echo "$output"
    task_bundle_with_digest="${output##*$'\n'}"

    # version placeholder is removed naturally by the substitution.
    real_task_name=$(yq e '.metadata.name' "$prepared_task_file")
    sub_expr_1="
	(.spec.tasks[].taskRef | select(.name == \"${real_task_name}\" and .version == \"${task_version}\" ))
	|= {\"name\": \"${real_task_name}\", \"bundle\": \"${task_bundle_with_digest}\"}
    "
    sub_expr_2="
	(.spec.finally[].taskRef | select(.name == \"${real_task_name}\" and .version == \"${task_version}\" ))
	|= {\"name\": \"${real_task_name}\", \"bundle\": \"${task_bundle_with_digest}\"}
    "
    for filename in $(find "$prepared_pipelines_dir" -name *.yaml)
    do
        yq e "$sub_expr_1" -i "${filename}"
        yq e "$sub_expr_2" -i "${filename}"
    done
done
)

# Build Pipeline bundle with pipelines pointing to newly built task bundles
(
    cd "$prepared_pipelines_dir"
    IFS=/
    find */*.yaml | while read -r category pipeline_yaml
    do
	real_pipeline_name=$(yq e '.metadata.name' "${category}/${pipeline_yaml}")
	partial_tag=${category}-${real_pipeline_name}
	pipeline_bundle=quay.io/${MY_QUAY_USER}/${TEST_REPO_NAME:-pipeline-${partial_tag}}:${TEST_REPO_NAME:+${partial_tag}-}$BUILD_TAG
	output=$(tkn bundle push "$pipeline_bundle" -f "${category}/${pipeline_yaml}")
	echo "$output"
	if [ "$category" == "hacbs" ]
	then
	    echo "$output" | save_ref "$pipeline_bundle" "$OUTPUT_PIPELINE_BUNDLE_LIST"
	fi
    done
)

if [ "$SKIP_DEVEL_TAG" == "" ] && [ "$MY_QUAY_USER" == "$QUAY_ORG" ] && [ -z "$TEST_REPO_NAME" ]; then
    for img in "$PIPELINE_BUNDLE_IMG" "$HACBS_BUNDLE_IMG" "$HACBS_BUNDLE_LATEST_IMG" "$HACBS_CORE_BUNDLE_IMG"; do
        NEW_TAG="${img%:*}:devel"
        skopeo copy "docker://${img}" "docker://${NEW_TAG}"
    done
fi

if [ "$SKIP_INSTALL" == "" ]; then
    "$SCRIPTDIR/util-install-bundle.sh" "$PIPELINE_BUNDLE_IMG" "$INSTALL_BUNDLE_NS"
fi
