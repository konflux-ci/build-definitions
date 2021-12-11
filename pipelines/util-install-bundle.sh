#!/bin/bash
SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

BUNDLE=$1
if [  -z "$BUNDLE" ]; then 
    echo "No Bundle Name"
    exit 1 
fi   
CM=$(mktemp)
cat > $CM <<OCILOCATION
apiVersion: v1
kind: ConfigMap
metadata:
  name: build-pipelines-defaults 
data: 
  default_build_bundle: "Your Bundle Here" 
OCILOCATION

yq -M e ".data.default_build_bundle=\"$BUNDLE\"" $CM | oc apply -f -

echo "Default Pipelines Configured to come from build-templates : "
oc get cm build-pipelines-defaults -n build-templates -o yaml | yq e '.data' -
echo "Override Pipelines Configured to come from $( oc project --short): "
oc get cm build-pipelines-defaults  -o yaml | yq e '.data' -
  

  