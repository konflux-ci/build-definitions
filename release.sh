#!/bin/bash

export BUILD_TAG=$1

if [ -z "$BUILD_TAG" ]; then
    echo "./release.sh BUILD_TAG"
    echo "Pass BUILD_TAG, tag must match with pushed git tag"
    exit 1
fi

CURRENT_HEAD_TAG=$(git describe --exact-match --tags 2>/dev/null)

if [ -z "$CURRENT_HEAD_TAG" ]; then
    echo "Current git branch is not tagged, tag with the BUILD tag first"
    exit 1
elif [ "$CURRENT_HEAD_TAG" != "$BUILD_TAG" ]; then
    echo "BUILD_TAG $BUILD_TAG is not matching current branch tag $CURRENT_HEAD_TAG"
    exit 1
fi

./tasks/appstudio-utils/release-build.sh -confirm
./pipelines/release-build.sh -confirm
