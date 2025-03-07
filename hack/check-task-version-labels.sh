#!/bin/bash
set -e -o pipefail

#
# This is a quick and throwaway, and meant to be used by a human, but it could
# in future be converted into a CI check.
#
# The goal is to show which task definitions have either a missing
# `app.kubernetes.io/version` label or a label that doesn't match the directory
# the definition is in.
#

# Find all the task definitions
ALL_TASK_VERSIONS=$(find task -mindepth 2 -maxdepth 2 -type d -name "?.?")

for task_version in $ALL_TASK_VERSIONS; do
  # Extract the task name and the version directory
  task_name=$(echo $task_version | awk -F'/' '{print $2}')
  expected_version=$(echo $task_version | awk -F'/' '{print $3}')

  # Extract the current value of the app.kubernetes.io/version label
  task_file=$task_version/$task_name.yaml
  found_version=$(yq '.metadata.labels["app.kubernetes.io/version"]' $task_file)

  # Trim to the right length so that version "0.2.1" is allowed in the "0.2" directory (I guess..?)
  trimmed_found_version="${found_version:0:${#expected_version}}"

  if [ ! "$trimmed_found_version" = "$expected_version" ]; then
    # Display the details if the version looks wrong
    printf "%-100s%s\n" $task_file "❌ Version $found_version does not match $expected_version"

  elif [ "$1" = "--verbose" ]; then
    # Be verbose if --verbose is on the command line
    printf "%-100s%s\n" $task_file "✔ Version $found_version matches $expected_version"
  fi
done
