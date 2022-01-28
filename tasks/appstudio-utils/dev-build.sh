#!/bin/bash

# local dev build script
SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

if [  -z "$MY_QUAY_USER" ]; then
    echo "MY_QUAY_USER is not set, skip this build."
    exit 0
fi
if [ "$MY_QUAY_USER" = "redhat-appstudio" ]; then
    echo "Cannot use devmode as redhat-appstudio user "
    exit 1  
fi
if [ -z "$BUILD_TAG" ]; then
    echo "Set BUILD_TAG to use devmode"
    exit 1
fi
IMG="quay.io/$MY_QUAY_USER/appstudio-utils:$BUILD_TAG"
echo "Using $MY_QUAY_USER to push results "
docker build -t $IMG $SCRIPTDIR
docker push $IMG

for TASK in $SCRIPTDIR/util-tasks/*.yaml ; do
    TASK_NAME=$(basename $TASK | sed 's/\.yaml//')
    if [ "$TASK_NAME" == "kustomization" ]; then
       continue
    fi
    yq -M e ".spec.steps[0].image=\"$IMG\"" $TASK | \
        tkn bundle push -f - quay.io/$MY_QUAY_USER/appstudio-tasks:$TASK_NAME-$BUILD_TAG
done 
