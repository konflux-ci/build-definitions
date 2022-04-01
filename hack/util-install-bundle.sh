#!/bin/bash
SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

BUNDLE=$1
if [  -z "$BUNDLE" ]; then 
    echo "No Bundle Name"
    exit 1 
fi   

oc create configmap build-pipelines-defaults --from-literal=default_build_bundle=$BUNDLE -o yaml --dry-run=client | oc apply -f-

echo "Default Pipelines Configured to come from build-templates : "
oc get cm build-pipelines-defaults -n build-templates -o jsonpath='{.data}{"\n"}'
echo "Override Pipelines Configured to come from $( oc project --short): "
oc get cm build-pipelines-defaults -o jsonpath='{.data}{"\n"}'
