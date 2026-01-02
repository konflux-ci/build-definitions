#!/bin/bash

# This script is called before applying the task to set up required resources
TASK_COPY="$1"
TEST_NS="$2"

# Create the service account if it doesn't exist
if ! kubectl get sa appstudio-pipeline -n "$TEST_NS" &>/dev/null; then
  kubectl create sa appstudio-pipeline -n "$TEST_NS"
fi

# Create a docker config secret for registry authentication
# This allows the clair-scan task to attach reports to the registry
# Check if the user has podman/docker credentials
if [ -f "${XDG_RUNTIME_DIR}/containers/auth.json" ]; then
  echo "Using podman credentials from ${XDG_RUNTIME_DIR}/containers/auth.json"
  kubectl create secret docker-registry redhat-appstudio-staginguser-pull-secret \
    --from-file=.dockerconfigjson="${XDG_RUNTIME_DIR}/containers/auth.json" \
    -n "$TEST_NS" --dry-run=client -o yaml | kubectl apply -f - -n "$TEST_NS"
elif [ -f "$HOME/.docker/config.json" ]; then
  echo "Using docker credentials from $HOME/.docker/config.json"
  kubectl create secret docker-registry redhat-appstudio-staginguser-pull-secret \
    --from-file=.dockerconfigjson="$HOME/.docker/config.json" \
    -n "$TEST_NS" --dry-run=client -o yaml | kubectl apply -f - -n "$TEST_NS"
else
  echo "WARNING: No registry credentials found."
  echo "The test may fail if write access is required to attach reports."
  echo "To fix this, log in to quay.io with: podman login quay.io"
  echo "Or create a secret manually with write access to quay.io/konflux-ci/konflux-test"
  # Create an empty secret to avoid errors, but it won't have valid credentials
  echo '{"auths":{}}' | kubectl create secret docker-registry redhat-appstudio-staginguser-pull-secret \
    --from-file=.dockerconfigjson=/dev/stdin \
    -n "$TEST_NS" --dry-run=client -o yaml | kubectl apply -f - -n "$TEST_NS" 2>/dev/null || true
fi

# Link the secret to the service account (this is what the task uses)
kubectl secrets link appstudio-pipeline redhat-appstudio-staginguser-pull-secret -n "$TEST_NS" 2>/dev/null || true

# Also link to default service account (used by Tekton if no service account is specified)
# This ensures credentials are available even if the PipelineRun doesn't specify a service account
kubectl secrets link default redhat-appstudio-staginguser-pull-secret -n "$TEST_NS" 2>/dev/null || true

# Note: The clair-scan task uses select-oci-auth which looks for credentials in
# $HOME/.docker/config.json in the container. The secret linked to the service account
# is used for image pulling, but for runtime access, credentials need to be available
# at that path. Since we cannot modify the task, ensure you have credentials with
# write access to the test image repository (quay.io/konflux-ci/konflux-test).
# The test may fail if credentials are not available or don't have write access.

echo "Pre-requirements setup complete"

