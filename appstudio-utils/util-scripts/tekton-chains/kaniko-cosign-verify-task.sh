#!/bin/bin/env bash

source $(dirname $0)/_helpers.sh
set -ue

TASK_LABEL=$1

counter=0
timeout=30
TASKRUN_NAME=`tkn tr list --label tekton.dev/task="${TASK_LABEL}" |awk '{print $1}' |tail -1`
while [ `tkn tr describe ${TASKRUN_NAME} -o  jsonpath='{.status.conditions[0].reason}'` != 'Succeeded' ] || [ $counter -gt $timeout ];
do
  echo "waiting for taskRun: $(tkn tr describe --last -o  jsonpath='{.metadata.name}') to finish"
  sleep 1
  counter=$((counter+1))
done
if [ $counter -gt $timeout ]; then
  echo "exiting with error"
  exit 1
fi

# Use a specific taskrun if provided, otherwise use the latest
TASKRUN_NAME=taskrun/$( echo $TASKRUN_NAME | sed 's#.*/##' )

# Let's not hard code the image url or the registry
IMAGE_URL=$( oc get $TASKRUN_NAME -o json | jq -r '.status.taskResults[1].value' )

SIG_KEY="k8s://tekton-chains/signing-secrets"

kaniko-cosign-verify $TASKRUN_NAME $IMAGE_URL $SIG_KEY
