#!/bin/bash

if [  -z "$MY_QUAY_USER" ]; then
    echo "MY_QUAY_USER environment variable must be set"
    exit 1
fi
if [ "$MY_QUAY_USER" = "redhat-appstudio" ]; then
    echo "Cannot use devmode as redhat-appstudio user "
    exit 1
fi
if [ -z "$BUILD_TAG" ]; then
    export BUILD_TAG=$(date +"%Y-%m-%d-%H%M%S")
fi

./tasks/appstudio-utils/dev-build.sh
./pipelines/dev-build.sh
