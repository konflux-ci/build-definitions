#!/bin/bash

# This script is called before applying the task to set up required resources
TASK_COPY="$1"
TEST_NS="$2"

# Create a dummy docker config secret for registry authentication
echo '{"auths":{}}' | kubectl create secret generic dummy-secret \
  --from-file=.dockerconfigjson=/dev/stdin \
  --type=kubernetes.io/dockerconfigjson \
  -n "$TEST_NS" --dry-run=client -o yaml | kubectl apply -f - -n "$TEST_NS"

echo "Pre-requirements setup complete" 
