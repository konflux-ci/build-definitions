#!/bin/bash
set -euo pipefail

# This hook modifies the buildah task before applying it in tests to reduce
# CPU requests. This prevents "Insufficient cpu" scheduling failures in
# resource-constrained CI environments (GitHub Actions Kind clusters).
#
# Args:
#   $1 - Path to the task YAML file (will be modified in-place)
#   $2 - Test namespace

TASK_FILE="$1"
TEST_NS="$2"

echo "INFO: Applying pre-apply-task-hook to reduce CPU requests for testing"

# Reduce CPU request from 1 to 250m (0.25 cores) for the build step
# This still allows the test to run but fits in resource-constrained environments
yq eval '.spec.steps[] |= (
  select(.name == "build").computeResources.requests.cpu = "250m"
)' -i "$TASK_FILE"

echo "INFO: Modified build step CPU request to 250m for test environment"
