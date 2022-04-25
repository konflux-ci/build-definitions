#!/usr/bin/bash
set -euo pipefail

# This file should contain conftest output in json format
CONFTEST_OUTPUT_FILE=$1

# Should be empty if there are no failures
TESTS_WITH_FAILURES=$( jq '.[] | select(has("failures")) | select(.failures|length > 0)' "$CONFTEST_OUTPUT_FILE" )

if [[ -z "$TESTS_WITH_FAILURES" ]]; then
  # No failures
  echo true

else
  # Some failures
  echo false

fi
