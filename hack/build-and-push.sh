#!/bin/bash -e

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

# Pushes the Tekton task bundle, captures the pushed bundle image reference
# including the digest and augments the pipelines with references to the task
# bundle for tasks identified by name
function push_tasks_bundle() {
    REF="$APPSTUDIO_TASKS_REPO:$BUILD_TAG-$PART"
    printf "\nCreating %s\n" "${REF}"
    OUT=$(tkn bundle push $TASKS $REF | save_ref $REF $OUTPUT_TASK_BUNDLE_LIST)
    echo "${OUT}"
    TASK_REF_WITH_DIGEST="${OUT##*$'\n'}" # the last line holds the image reference with tag and digest
    for pipeline in "$PIPELINE_TEMP"/*.yaml; do
        for task_name in "${TASK_NAMES[@]}"; do
            yq e -i "(.spec.tasks[].taskRef | select(.name == \"${task_name}\")) |= {\"name\": \"${task_name}\", \"bundle\":\"${TASK_REF_WITH_DIGEST}\"}" "${pipeline}"
            yq e -i "(.spec.finally[].taskRef | select(.name == \"${task_name}\")) |= {\"name\": \"${task_name}\", \"bundle\":\"${TASK_REF_WITH_DIGEST}\"}" "${pipeline}"
        done
    done
}

# local dev build script
SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

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
    if [ "$MY_QUAY_USER" == "redhat-appstudio" ]; then
        echo "'redhat-appstudio' repo is used, define BUILD_TAG"
        exit 1
    else
        BUILD_TAG=$(date +"%Y-%m-%d-%H%M%S")
        echo "BUILD_TAG is not defined, using $BUILD_TAG"
    fi
fi

# Specify TEST_REPO_NAME env var if you want to push all images to a single quay repository
# (This method is used in PR testing)
: "${TEST_REPO_NAME:=}"

APPSTUDIO_UTILS_IMG="quay.io/$MY_QUAY_USER/${TEST_REPO_NAME:-appstudio-utils}:${TEST_REPO_NAME:+build-definitions-utils-}$BUILD_TAG"
APPSTUDIO_TASKS_REPO=quay.io/$MY_QUAY_USER/${TEST_REPO_NAME:-appstudio-tasks}
PIPELINE_BUNDLE_IMG=quay.io/$MY_QUAY_USER/${TEST_REPO_NAME:-build-templates-bundle}:${TEST_REPO_NAME:+build-}$BUILD_TAG
KCP_BUNDLE_IMG=quay.io/$MY_QUAY_USER/${TEST_REPO_NAME:-kcp-templates-bundle}:${TEST_REPO_NAME:+kcp-}$BUILD_TAG
HACBS_BUNDLE_IMG=quay.io/$MY_QUAY_USER/${TEST_REPO_NAME:-hacbs-templates-bundle}:${TEST_REPO_NAME:+hacbs-}$BUILD_TAG
HACBS_BUNDLE_LATEST_IMG=quay.io/$MY_QUAY_USER/${TEST_REPO_NAME:-hacbs-templates-bundle}:${TEST_REPO_NAME:+hacbs-}latest
HACBS_CORE_BUNDLE_IMG=quay.io/$MY_QUAY_USER/${TEST_REPO_NAME:-hacbs-core-service-templates-bundle}:${TEST_REPO_NAME:+hacbs-core-}latest

OUTPUT_TASK_BUNDLE_LIST="${OUTPUT_TASK_BUNDLE_LIST-task-bundle-list}"
OUTPUT_PIPELINE_BUNDLE_LIST="${OUTPUT_PIPELINE_BUNDLE_LIST-pipeline-bundle-list}"
rm -f "${OUTPUT_TASK_BUNDLE_LIST}" "${OUTPUT_PIPELINE_BUNDLE_LIST}"

# Build appstudio-utils image
if [ "$SKIP_BUILD" == "" ]; then
    echo "Using $MY_QUAY_USER to push results "
    docker build -t $APPSTUDIO_UTILS_IMG $SCRIPTDIR/../appstudio-utils/
    docker push $APPSTUDIO_UTILS_IMG
fi

# Create bundles with tasks
PART=1
COUNT=0
TASK_TEMP=$(mktemp -d)
PIPELINE_TEMP=$(mktemp -d)
oc kustomize $SCRIPTDIR/../tasks | $CSPLIT_CMD -s -f $TASK_TEMP/task -b %02d.yaml - /^---$/ '{*}'
oc kustomize $SCRIPTDIR/../pipelines/base > ${PIPELINE_TEMP}/base.yaml
oc kustomize $SCRIPTDIR/../pipelines/base-no-shared > ${PIPELINE_TEMP}/base-no-shared.yaml
oc kustomize $SCRIPTDIR/../pipelines/hacbs > ${PIPELINE_TEMP}/hacbs.yaml
oc kustomize $SCRIPTDIR/../pipelines/hacbs-core-service > ${PIPELINE_TEMP}/hacbs-core-service.yaml

## Limit number of tasks in bundle
MAX=10
TASKS=
REF="$APPSTUDIO_TASKS_REPO:$BUILD_TAG-$PART"
TASK_NAMES=()
for TASK in $TASK_TEMP/task*.yaml; do
    TASK_NAME=$(yq e ".metadata.name" "$TASK")
    TASK_NAMES+=("$TASK_NAME")
    # Replace appstudio-utils placeholder by newly build appstudio-utils image
    yq e -i ".spec.steps[] |= select(.image == \"appstudio-utils\").image=\"$APPSTUDIO_UTILS_IMG\"" "$TASK"
    TASKS="$TASKS -f $TASK"
    COUNT=$((COUNT+1))
    if [ $COUNT -eq $MAX ]; then
        push_tasks_bundle

        COUNT=0
        PART=$((PART+1))
        TASKS=
        TASK_NAMES=()
    fi
done
push_tasks_bundle # push the leftover tasks when the remaining $COUNT < $MAX

# Build Pipeline bundle with pipelines pointing to newly built appstudio-tasks
tkn bundle push $PIPELINE_BUNDLE_IMG -f ${PIPELINE_TEMP}/base.yaml | save_ref $PIPELINE_BUNDLE_IMG $OUTPUT_PIPELINE_BUNDLE_LIST
tkn bundle push $HACBS_BUNDLE_IMG -f ${PIPELINE_TEMP}/hacbs.yaml
tkn bundle push $KCP_BUNDLE_IMG -f ${PIPELINE_TEMP}/base-no-shared.yaml
tkn bundle push $HACBS_BUNDLE_LATEST_IMG -f ${PIPELINE_TEMP}/hacbs.yaml
tkn bundle push $HACBS_CORE_BUNDLE_IMG -f ${PIPELINE_TEMP}/hacbs-core-service.yaml

if [ "$SKIP_DEVEL_TAG" == "" ] && [ "$MY_QUAY_USER" == "redhat-appstudio" ] && [ -z "$TEST_REPO_NAME" ]; then
    for img in "$PIPELINE_BUNDLE_IMG" "$KCP_BUNDLE_IMG" "$HACBS_BUNDLE_IMG" "$HACBS_BUNDLE_LATEST_IMG" "$HACBS_CORE_BUNDLE_IMG"; do
        NEW_TAG="${img%:*}:devel"
        skopeo copy "docker://${img}" "docker://${NEW_TAG}"
    done
fi

if [ "$SKIP_INSTALL" == "" ]; then
    $SCRIPTDIR/util-install-bundle.sh $PIPELINE_BUNDLE_IMG $INSTALL_BUNDLE_NS
fi
