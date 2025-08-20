#!/bin/bash

# This script generates a README.md for a Tekton Task.
# It preserves a manually edited "Warning" section at the top and a "Additional info" section at the bottom.
#
# The "Warning" section will only be included in the output if it already exists in the README.md file.
# It will copy everything until the first H1 (e.g., # This is H1) line.
#
# Usage:
# ## Warning
# Task is deprecated, do not use.
#
# The "Additional info" section will always be present, either with its preserved content or as an empty section.
#
# Usage:
# ./hack/generate-readme.sh /path/to/task.yaml /path/to/README.md

TASK_PATH=$1
README_PATH=$2

if [ -z "$README_PATH" ]; then
  echo "Usage: $0 \$PATH_TO_TASK_YAML \$PATH_TO_README"
  exit 1
fi

if [ ! -f "$TASK_PATH" ]; then
  echo "Error: Task file not found at $TASK_PATH"
  exit 1
fi

WARNING_SECTION=""
ADDITIONAL_INFO=""
if [ -f "$README_PATH" ]; then
    # find the warning section (from "## Warning" to the next H1 "#")
    WARNING_SECTION=$(awk '/^## Warning/{flag=1;next} /^# /{flag=0} flag' "$README_PATH")

    # find the "Additional info" heading and capture everything from that point to the end
    ADDITIONAL_INFO=$(awk '/^## Additional info/ {found=1} found' "$README_PATH")
fi

{
  if [ -n "$WARNING_SECTION" ]; then
    echo "## Warning"
    echo "$WARNING_SECTION"
    echo
  fi

  echo "# $(yq '.metadata.name' "$TASK_PATH") $(yq '.kind | downcase' "$TASK_PATH")"
  echo
  yq '.spec.description' "$TASK_PATH"
  echo

  if [[ $(yq '.spec.params | length' "$TASK_PATH") -gt 0 ]]; then
    PARAMS=$(yq '
        .spec.params.[] |
        with(select(.default | type == "!!seq"); .default = (.default | tojson(0))) |
        (
            "|" + .name +
            "|" + (.description // "" | sub("\n", " ")) +
            "|" + (.default // (.default != "*" | "")) +
            "|" + (.default != "*") + "|"
        )' "$TASK_PATH"
    )

    echo "## Parameters"
    echo "|name|description|default value|required|"
    echo "|---|---|---|---|"
    echo "$PARAMS" | sed 's/||false|$/|""|false|/'
    echo
  fi

  if [[ $(yq '.spec.results | length' "$TASK_PATH") -gt 0 ]]; then
    RESULTS=$(yq '.spec.results.[] | ("|" + .name + "|" + (.description // "" | sub("\n", " ")) + "|")' "$TASK_PATH")

    echo "## Results"
    echo "|name|description|"
    echo "|---|---|"
    echo "$RESULTS"
    echo
  fi

  if [[ $(yq '.spec.workspaces | length' "$TASK_PATH") -gt 0 ]]; then
    WORKSPACES=$(yq '.spec.workspaces.[] | ("|" + .name + "|" + (.description // "" | sub("\n", " ")) + "|" + (.optional // "false") + "|")' "$TASK_PATH")

    echo "## Workspaces"
    echo "|name|description|optional|"
    echo "|---|---|---|"
    echo "$WORKSPACES"
  fi
} > "$README_PATH"

# if content was found, append it back at the end; else add an empty section
if [ -n "$ADDITIONAL_INFO" ]; then
    echo "" >> "$README_PATH"
    echo "$ADDITIONAL_INFO" >> "$README_PATH"
else
    echo "" >> "$README_PATH"
    echo "## Additional info" >> "$README_PATH"
fi
