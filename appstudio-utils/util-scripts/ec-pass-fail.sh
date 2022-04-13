#!/usr/bin/bash
set -euo pipefail

# Derive a pass/fail value from the OPA output
#
# It might change in future so define it here rather than
# put the logic directly in the task definition
#
# See also tasks/enterprise-contract.yaml

OPA_OUTPUT_FILE=$1
OPA_OUTPUT=$( cat $OPA_OUTPUT_FILE )

if [[ "$OPA_OUTPUT" == '[]' ]]; then
  # An empty list of deny reasons means all the checks passed
  echo true

else
  # Anything else means it failed
  echo false

fi
