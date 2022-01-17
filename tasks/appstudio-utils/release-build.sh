#!/bin/bash

# local build script
SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

if [ -z "$BUILD_TAG" ]; then
    echo "BUILD_TAG environment variable has to be set."
    exit 1
fi

IMG="quay.io/redhat-appstudio/appstudio-utils:$BUILD_TAG"

echo "Warning: You are updating an image in redhat-appstudio" 
echo "This is disabled unless you pass -confirm on the cmdline"
if [ "$1" = "-confirm" ]; then 
    echo "Creating Release $IMG "
    echo "Using redhat-appstudio quay.io user to push results "
    echo "The tasks in util-tasks need to be updated to reference this tag "
    echo "The gitops repo for app studio needs to have ClusterTasks created for the tasks in util-task."
    docker build -t $IMG $SCRIPTDIR
    docker push $IMG

    for TASK in $SCRIPTDIR/util-tasks/*.yaml ; do
        TASK_NAME=$(basename $TASK | sed 's/\.yaml//')
        yq -M e ".spec.steps[0].image=\"$IMG\"" $TASK | \
            tkn bundle push -f - quay.io/redhat-appstudio/appstudio-tasks:$TASK_NAME-$BUILD_TAG
    done

else 
    echo "Cannot push to redhat-appstudio without a -confirm on command line."
    exit 1 
fi 
