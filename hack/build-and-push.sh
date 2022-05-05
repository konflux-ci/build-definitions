#!/bin/bash -e

# local dev build script
SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

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

APPSTUDIO_UTILS_IMG="quay.io/$MY_QUAY_USER/appstudio-utils:$BUILD_TAG"

# Build appstudio-utils image
if [ "$SKIP_BUILD" == "" ]; then
    echo "Using $MY_QUAY_USER to push results "
    docker build -t $APPSTUDIO_UTILS_IMG $SCRIPTDIR/../appstudio-utils/
    docker push $APPSTUDIO_UTILS_IMG
fi

# Create bundles with tasks
APPSTUDIO_TASKS_REPO=quay.io/$MY_QUAY_USER/appstudio-tasks
PART=1
COUNT=0
TASK_TEMP=$(mktemp -d)
PIPELINE_TEMP=$(mktemp -d)
oc kustomize $SCRIPTDIR/../tasks | csplit -s -f $TASK_TEMP/task -b %02d.yaml - /^---$/ '{*}'
oc kustomize $SCRIPTDIR/../pipelines/base > ${PIPELINE_TEMP}/base.yaml
oc kustomize $SCRIPTDIR/../pipelines/hacbs > ${PIPELINE_TEMP}/hacbs.yaml
oc kustomize $SCRIPTDIR/../pipelines/hacbs-core-service > ${PIPELINE_TEMP}/hacbs-core-service.yaml

## Limit number of tasks in bundle
MAX=10
TASKS=
REF="$APPSTUDIO_TASKS_REPO:$BUILD_TAG-$PART"
for TASK in $TASK_TEMP/task*.yaml; do
    TASK_NAME=$(yq e ".metadata.name" $TASK)
    if [ $COUNT -eq $MAX ]; then
        echo Creating $REF
        tkn bundle push $TASKS $REF
        COUNT=0
        PART=$((PART+1))
        TASKS=
    fi
    REF="$APPSTUDIO_TASKS_REPO:$BUILD_TAG-$PART"
    # Replace appstidio-utils placeholder by newly build appstudio-utils image
    yq e -i ".spec.steps[] |= select(.image == \"appstudio-utils\").image=\"$APPSTUDIO_UTILS_IMG\"" $TASK
    TASKS="$TASKS -f $TASK"
    for file in $PIPELINE_TEMP/*.yaml; do
        yq e -i "(.spec.tasks[].taskRef | select(.name == \"$TASK_NAME\")) |= {\"name\": \"$TASK_NAME\", \"bundle\":\"$REF\"}" $file
        yq e -i "(.spec.finally[].taskRef | select(.name == \"$TASK_NAME\")) |= {\"name\": \"$TASK_NAME\", \"bundle\":\"$REF\"}" $file
    done
    COUNT=$((COUNT+1))
done
echo Creating $APPSTUDIO_TASKS_REPO:$BUILD_TAG-$PART
tkn bundle push $TASKS $REF

# Build Pipeline budle with pipelines pointing to newly built appstudio-tasks
PIPELINE_BUNDLE=quay.io/$MY_QUAY_USER/build-templates-bundle:$BUILD_TAG
tkn bundle push $PIPELINE_BUNDLE -f ${PIPELINE_TEMP}/base.yaml

HACBS_BUNDLE=quay.io/$MY_QUAY_USER/hacbs-templates-bundle:$BUILD_TAG
tkn bundle push $HACBS_BUNDLE -f ${PIPELINE_TEMP}/hacbs.yaml

HACBS_CORE_BUNDLE=quay.io/$MY_QUAY_USER/hacbs-core-service-templates-bundle:latest
tkn bundle push $HACBS_CORE_BUNDLE -f ${PIPELINE_TEMP}/hacbs-core-service.yaml

if [ "$SKIP_INSTALL" == "" ]; then
    $SCRIPTDIR/util-install-bundle.sh $PIPELINE_BUNDLE
fi
