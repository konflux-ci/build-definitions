#!/usr/bin/env bash
#
# A wrapper for cosign to help verify a signed image
#

# Required
IMAGE_URL=$1
SIG_KEY=$2
VERBOSE=$3

source $(dirname $0)/_helpers.sh

cosign-verify $IMAGE_URL $SIG_KEY $VERBOSE
