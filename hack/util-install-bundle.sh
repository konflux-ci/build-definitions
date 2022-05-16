#!/bin/bash
SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

BUNDLE=$1
NAMESPACE=${2:-$(oc project -q)}
if [  -z "$BUNDLE" ]; then 
    echo "No Bundle Name"
    exit 1 
fi   

oc create configmap build-pipelines-defaults --from-literal=default_build_bundle=$BUNDLE -o yaml --dry-run=client | oc -n "$NAMESPACE" apply -f-

echo "Default Pipelines configured to come from the namespace 'build-templates':"
oc get cm build-pipelines-defaults -n build-templates -o jsonpath='{.data}{"\n"}'
echo "Override Pipelines configured to come from the namespace '$NAMESPACE':"
oc get cm build-pipelines-defaults -n "$NAMESPACE" -o jsonpath='{.data}{"\n"}'
