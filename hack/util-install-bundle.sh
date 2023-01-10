#!/bin/bash

set -e -o pipefail

SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

BUNDLE=$1
NAMESPACE=${2:-$(oc project -q)}
if [  -z "$BUNDLE" ]; then 
    echo "No Bundle Name"
    exit 1 
fi

cat << EOF | oc -n "$NAMESPACE" apply -f-
apiVersion: appstudio.redhat.com/v1alpha1
kind: BuildPipelineSelector
metadata:
  name: build-pipeline-selector
spec:
  selectors:
    - name: Docker build
      pipelineRef:
        name: docker-build
        bundle: ${BUNDLE}
      when:
        dockerfile: true
EOF

echo "Overridden Pipeline selectors configured to come from the namespace '$NAMESPACE':"
oc get buildpipelineselector build-pipeline-selector -n "$NAMESPACE" -o yaml | yq '.spec.selectors'
