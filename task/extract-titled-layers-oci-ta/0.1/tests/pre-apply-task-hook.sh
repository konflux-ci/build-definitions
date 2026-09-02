#!/bin/bash
# Kind registry TLS is not reliably trusted via the mounted trusted-ca bundle
# under deploy-local CI. Opt the task into insecure registry mode for tests only.
TASK_COPY="$1"

yq -i '
  .spec.stepTemplate.env = (.spec.stepTemplate.env // []) + [
    {"name": "ORAS_OPTIONS", "value": "--insecure"}
  ]
' "$TASK_COPY"

echo "Pre-requirements setup complete"
