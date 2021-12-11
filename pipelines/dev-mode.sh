#!/bin/bash
SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

TEMPLATES=$SCRIPTDIR/build-templates-bundle
 
if [  -z "$MY_QUAY_USER" ]; then 
    echo "Set MY_QUAY_USER to use devmode"
    exit 1 
fi   
if [ "$MY_QUAY_USER" = "redhat-appstudio" ]; then
    echo "Cannot use devmode as redhat-appstudio user "
    exit 1  
fi
BUILD_TAG=$(date +"%Y-%m-%d-%H%M%S") 
BUNDLE=quay.io/$MY_QUAY_USER/build-templates-bundle:v$BUILD_TAG

$SCRIPTDIR/util-package-bundle.sh $BUNDLE
  
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

echo "Pipelines Configured to come from: "
oc get cm build-pipelines-defaults  -o yaml | yq e '.data' -
  



  