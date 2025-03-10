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
ALL_TASK_VERSIONS=$(find task -mindepth 2 -maxdepth 2 -type d)

RED="\e[31m✘\e[0m"
GREEN="\e[32m✔\e[0m"
HFORMAT="%-97s %-4s %-9s\n"
FORMAT="%b %-95s %-4s %-9s\n"

HEADER=$(printf "$HFORMAT" "Task" "Dir" "Label")
echo "$HEADER"
echo "$HEADER" | tr '[:graph:]' '='

for task_version in $ALL_TASK_VERSIONS; do
  # Extract the task name and the version directory
  task_name=$(awk -F'/' '{print $2}' <<< "$task_version")
  dir_version=$(awk -F'/' '{print $3}' <<< "$task_version")

  # Extract the current value of the app.kubernetes.io/version label
  task_file="$task_version/$task_name.yaml"
  label_version=$(yq '.metadata.labels["app.kubernetes.io/version"]' "$task_file")

  # Trim to the right length so that version "0.2.1" is allowed in the "0.2" directory (I guess..?)
  trimmed_label_version="${label_version:0:${#dir_version}}"


  if [ "$label_version" = "null" ]; then
    # Missing
    printf "$FORMAT" "$RED" "$task_file" "$dir_version" "Missing"

  elif [ ! "$trimmed_label_version" = "$dir_version" ]; then
    # Looks incorrect
    printf "$FORMAT" "$RED" "$task_file" "$dir_version" "$label_version"

  elif [ "$1" = "--verbose" ]; then
    # Looks correct
    printf "$FORMAT" "$GREEN" "$task_file" "$dir_version" "$label_version"

  fi
done
