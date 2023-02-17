#!/bin/bash

set -e -o pipefail

BUNDLES=$1
NAMESPACE=${2:-$(oc project -q)}
if [  -z "$BUNDLES" ]; then 
    echo "No Pipeline Bundles specified"
    exit 1 
fi

IFS=',' read -ra BUNDLE <<< "$BUNDLES"
for i in "${BUNDLE[@]}"; do
  if [[ $i == *"docker-build"* ]]; then
    DOCKER_BUNDLE=$i
  elif [[ $i == *"fbc-builder"* ]]; then
    FBC_BUNDLE=$i
  fi
done

cat << EOF | oc -n "$NAMESPACE" apply -f-
apiVersion: appstudio.redhat.com/v1alpha1
kind: BuildPipelineSelector
metadata:
  name: build-pipeline-selector
spec:
  selectors:
    - name: Hermetic build - golang
      pipelineParams:
        - name: hermetic
          value: "true"
        - name: prefetch-input
          value: "gomod"
      pipelineRef:
        name: docker-build
        bundle: ${DOCKER_BUNDLE}
      when:
        dockerfile: true
        language: Go
        projectType: test-hermetic-build
    - name: Hermetic build - python
      pipelineParams:
        - name: hermetic
          value: "true"
        - name: prefetch-input
          value: "pip"
      pipelineRef:
        name: docker-build
        bundle: ${DOCKER_BUNDLE}
      when:
        dockerfile: true
        language: Python
        projectType: test-hermetic-build
    - name: Docker build
      pipelineRef:
        name: docker-build
        bundle: ${DOCKER_BUNDLE}
      when:
        dockerfile: true
    - name: FBC
      pipelineRef:
        name: fbc-builder
        bundle: ${FBC_BUNDLE}
      when:
        language: fbc
EOF

echo "Overridden Pipeline selectors configured to come from the namespace '$NAMESPACE':"
oc get buildpipelineselector build-pipeline-selector -n "$NAMESPACE" -o yaml | yq '.spec.selectors'
