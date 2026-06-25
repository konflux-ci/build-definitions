#!/bin/bash
set -euo pipefail

# Patches the build-vm-image task for testing in a kind cluster.
# Replaces the untestable steps (use-trusted-artifact, validate-bib-config, build)
# with lightweight mocks so the real SBOM steps can run against mocked outputs.

TASK_COPY="$1"
TEST_NS="$2"

export TASK_RUNNER_IMAGE="quay.io/konflux-ci/task-runner:1.6.0@sha256:1abfe4e50d4e961d0fd9790202565f93ee650fe8dfc50932c94989acba10485f"

# --- Volume fixes ---

# Make the ssh secret optional (it won't exist in kind)
yq -i '(.spec.volumes[] | select(.name == "ssh")).secret.optional = true' "$TASK_COPY"

# Add trusted-ca volume for kind registry TLS
yq -i '.spec.volumes += [{"name": "trusted-ca", "configMap": {"name": "trusted-ca", "items": [{"key": "ca-bundle.crt", "path": "ca-bundle.crt"}], "optional": true}}]' "$TASK_COPY"

# Add trusted-ca volumeMount to stepTemplate
yq -i '.spec.stepTemplate.volumeMounts += [{"name": "trusted-ca", "mountPath": "/etc/pki/tls/certs/ca-custom-bundle.crt", "subPath": "ca-bundle.crt", "readOnly": true}]' "$TASK_COPY"

# --- Step replacements ---

# 1. Replace use-trusted-artifact with a no-op
export MOCK_UTA_SCRIPT='#!/bin/bash
echo "mock: trusted artifact step skipped"
'
yq -i '
  (.spec.steps[] | select(.name == "use-trusted-artifact")) = {
    "name": "use-trusted-artifact",
    "image": env(TASK_RUNNER_IMAGE),
    "computeResources": {"limits": {"memory": "64Mi"}, "requests": {"cpu": "50m", "memory": "64Mi"}},
    "script": strenv(MOCK_UTA_SCRIPT)
  }
' "$TASK_COPY"

# 2. Replace validate-bib-config with a mock that writes /var/workdir/vars
export MOCK_VALIDATE_SCRIPT='#!/bin/bash
set -euo pipefail
echo "mock: writing test vars to /var/workdir/vars"
cat > /var/workdir/vars <<VARS
declare SOURCE_IMAGE=registry-service.kind-registry/test-source:test
declare BOOTC_BUILDER_IMAGE=unused
declare TAGGED_AS=unused
VARS
cat /var/workdir/vars
'
yq -i '
  (.spec.steps[] | select(.name == "validate-bib-config")) = {
    "name": "validate-bib-config",
    "image": env(TASK_RUNNER_IMAGE),
    "computeResources": {"limits": {"memory": "64Mi"}, "requests": {"cpu": "50m", "memory": "64Mi"}},
    "script": strenv(MOCK_VALIDATE_SCRIPT)
  }
' "$TASK_COPY"

# 3. Replace build with a mock that pushes a dummy artifact and writes results
export MOCK_BUILD_SCRIPT='#!/bin/bash
set -euo pipefail

if [ "${IMAGE_APPEND_PLATFORM}" == "true" ]; then
  OUTPUT_IMAGE="${OUTPUT_IMAGE}-${PLATFORM//[^a-zA-Z0-9]/-}"
fi

echo "mock: pushing dummy disk image artifact to ${OUTPUT_IMAGE}"
cd /tmp && echo "test-disk-content" > disk.qcow2
oras push --no-tty "${OUTPUT_IMAGE}" disk.qcow2

DIGEST=$(oras resolve "${OUTPUT_IMAGE}")
echo "mock: pushed with digest ${DIGEST}"

echo -n "${OUTPUT_IMAGE}" > /tekton/results/IMAGE_URL
echo -n "${DIGEST}" > /tekton/results/IMAGE_DIGEST
echo -n "${OUTPUT_IMAGE}@${DIGEST}" > /tekton/results/IMAGE_REFERENCE
echo "mock: results written"
'
yq -i '
  (.spec.steps[] | select(.name == "build")) = {
    "name": "build",
    "image": env(TASK_RUNNER_IMAGE),
    "computeResources": {"limits": {"memory": "128Mi"}, "requests": {"cpu": "50m", "memory": "64Mi"}},
    "script": strenv(MOCK_BUILD_SCRIPT)
  }
' "$TASK_COPY"

echo "Task patched for testing"
