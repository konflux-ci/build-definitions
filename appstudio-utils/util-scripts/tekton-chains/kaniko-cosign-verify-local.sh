#!/bin/bash

source $(dirname $0)/_helpers.sh
set -ue

# Use a specific taskrun if provided, otherwise use the latest
TASKRUN_NAME=${1:-$( tkn taskrun describe --last -o name )}
TASKRUN_NAME=taskrun/$( echo $TASKRUN_NAME | sed 's#.*/##' )

# Let's not hard code the image url or the registry
IMAGE_URL=$( oc get $TASKRUN_NAME -o json | jq -r '.status.taskResults[1].value' )
IMAGE_REGISTRY=$( echo $IMAGE_URL | cut -d/ -f1 )
#IMAGE_REGISTRY=$( oc registry info )

SIG_KEY="k8s://tekton-chains/signing-secrets"

title "Make sure we're logged in to the registry"
# Make sure we have a docker credential since cosign will need it
# (Todo: Probably shouldn't assume kubeadmin user here)
oc whoami -t | docker login -u kubeadmin --password-stdin $IMAGE_REGISTRY

kaniko-cosign-verify $TASKRUN_NAME $IMAGE_URL $SIG_KEY
