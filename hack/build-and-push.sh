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
TASK_TEMP=$(mktemp)
PIPELINE_TEMP=$(mktemp -d)
cp $SCRIPTDIR/../pipelines/*.yaml ${PIPELINE_TEMP}

## Limit number of tasks in bundle
MAX=10
for TASK in $SCRIPTDIR/../tasks/*.yaml; do
    TASK_NAME=$(basename $TASK | sed 's/\.yaml//')
    if [ "$TASK_NAME" == "kustomization" ]; then
       continue
    fi
    if [ $COUNT -eq $MAX ]; then
        echo Creating $TASK_TEMP $APPSTUDIO_TASKS_REPO:$BUILD_TAG-$PART
        tkn bundle push -f $TASK_TEMP $APPSTUDIO_TASKS_REPO:$BUILD_TAG-$PART
        COUNT=0
        PART=$((PART+1))
        rm $TASK_TEMP
    fi
    # Replace appstidio-utils placeholder by newly build appstudio-utils image
    if yq -M -e e ".spec.steps[0].image==\"appstudio-utils\"" $TASK &>/dev/null; then
        yq -M e ".spec.steps[0].image=\"$APPSTUDIO_UTILS_IMG\"" $TASK >> $TASK_TEMP
    else
        cat $TASK >> $TASK_TEMP
    fi
    echo --- >> $TASK_TEMP
    REF="$APPSTUDIO_TASKS_REPO:$BUILD_TAG-$PART"
    for file in $PIPELINE_TEMP/*.yaml; do
        yq e -i "(.spec.tasks[].taskRef | select(.name == \"$TASK_NAME\")) |= {\"name\": \"$TASK_NAME\", \"bundle\":\"$REF\"}" $file
        yq e -i "(.spec.finally[].taskRef | select(.name == \"$TASK_NAME\")) |= {\"name\": \"$TASK_NAME\", \"bundle\":\"$REF\"}" $file
    done
    COUNT=$((COUNT+1))
done
echo Creating $APPSTUDIO_TASKS_REPO:$BUILD_TAG-$PART
tkn bundle push -f $TASK_TEMP $APPSTUDIO_TASKS_REPO:$BUILD_TAG-$PART

# Build Pipeline budle with pipelines pointing to newly built appstudio-tasks
PIPELINE_BUNDLE=quay.io/$MY_QUAY_USER/build-templates-bundle:$BUILD_TAG
for file in $PIPELINE_TEMP/*.yaml; do
    if echo $file | grep -q "kustomization.yaml"; then
       continue
    fi
    PARAMS="$PARAMS -f $file "
done
echo Creating $PIPELINE_BUNDLE
tkn bundle push $PIPELINE_BUNDLE $PARAMS

if [ "$SKIP_INSTALL" == "" ]; then
    $SCRIPTDIR/util-install-bundle.sh $PIPELINE_BUNDLE
fi
