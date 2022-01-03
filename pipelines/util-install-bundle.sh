#!/bin/bash
SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

BUNDLE=$1
if [  -z "$BUNDLE" ]; then 
    echo "No Bundle Name"
    exit 1 
fi   

oc delete configmap build-pipelines-defaults
oc create configmap build-pipelines-defaults --from-literal=default_build_bundle="$BUNDLE"

echo "Default Pipelines Configured to come from build-templates : "
oc get cm build-pipelines-defaults -n build-templates -o yaml | yq e '.data' -
echo "Override Pipelines Configured to come from $( oc project --short): "
oc get cm build-pipelines-defaults  -o yaml | yq e '.data' -
