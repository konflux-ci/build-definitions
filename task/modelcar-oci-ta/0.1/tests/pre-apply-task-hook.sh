#!/bin/bash

# This script is called before applying the task to set up required resources
TASK_COPY="$1"

# Extract task directory and name from the task file path
# The task file is in /tmp/task.XXXXXX, but we need to get the original path
# We'll use the current working directory to determine the task path
TASK_DIR="task/modelcar-oci-ta/0.1"
TASK_NAME="modelcar-oci-ta"
TASK_VERSION="0.1"
TASK_VERSION_WITH_HYPHEN="$(echo $TASK_VERSION | tr '.' '-')"
TEST_NS="${TASK_NAME}-${TASK_VERSION_WITH_HYPHEN}"

echo "Setting up pre-requirements for task $TASK_NAME in namespace $TEST_NS"

# Create a dummy docker config secret for registry authentication
echo '{"auths":{}}' | kubectl create secret generic dummy-secret \
  --from-file=.dockerconfigjson=/dev/stdin \
  --type=kubernetes.io/dockerconfigjson \
  -n "$TEST_NS" --dry-run=client -o yaml | kubectl apply -f - -n "$TEST_NS"

echo "Pre-requirements setup complete" 
