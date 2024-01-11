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
  elif [[ $i == *"nodejs-builder"* ]]; then
    NODEJS_BUNDLE=$i
  elif [[ $i == *"java-builder"* ]]; then
    JAVA_BUNDLE=$i
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
        resolver: bundles
        params:
        - name: name
          value: docker-build
        - name: bundle
          value: ${DOCKER_BUNDLE}
        - name: kind
          value: pipeline
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
        resolver: bundles
        params:
        - name: name
          value: docker-build
        - name: bundle
          value: ${DOCKER_BUNDLE}
        - name: kind
          value: pipeline
      when:
        dockerfile: true
        language: Python
        projectType: test-hermetic-build
    - name: FBC build
      pipelineRef:
        resolver: bundles
        params:
        - name: name
          value: fbc-builder
        - name: bundle
          value: ${FBC_BUNDLE}
        - name: kind
          value: pipeline
      when:
        language: fbc
    - name: S2I - NodeJS
      pipelineRef:
        resolver: bundles
        params:
        - name: name
          value: nodejs-builder
        - name: bundle
          value: ${NODEJS_BUNDLE}
        - name: kind
          value: pipeline
      when:
        language: nodejs
    - name: S2I - Java
      pipelineRef:
        resolver: bundles
        params:
        - name: name
          value: java-builder
        - name: bundle
          value: ${JAVA_BUNDLE}
        - name: kind
          value: pipeline
      when:
        language: java
    - name: Docker build
      pipelineRef:
        resolver: bundles
        params:
        - name: name
          value: docker-build
        - name: bundle
          value: ${DOCKER_BUNDLE}
        - name: kind
          value: pipeline
      when:
        dockerfile: true
EOF

echo "Overridden Pipeline selectors configured to come from the namespace '$NAMESPACE':"
oc get buildpipelineselector build-pipeline-selector -n "$NAMESPACE" -o yaml | yq '.spec.selectors'
