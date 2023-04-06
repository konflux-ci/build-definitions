#!/bin/bash

TASK=$1
if [ ! -f "$TASK" ]; then
  echo "Usage: $0 \$PATH_TO_TASK"
  exit 1
fi
echo "# $(yq '.metadata.name' $TASK) task"
echo
yq '.spec.description' $TASK
echo
PARAMS=$(yq '.spec.params.[] | ("|" + .name + "|" + (.description // "" | sub("\n", " ")) + "|" + (.default // (.default != "*" | "")) + "|" + (.default != "*") + "|")' $TASK)
if [ -n "$PARAMS" ]; then
  echo "## Parameters"
  echo "|name|description|default value|required|"
  echo "|---|---|---|---|"
  echo "$PARAMS" | sed 's/||false|$/|""|false|/'
  echo
fi

RESULTS=$(yq '.spec.results.[] | ("|" + .name + "|" + (.description // "" | sub("\n", " ")) + "|")' $TASK)
if [ -n "$RESULTS" ]; then
  echo "## Results"
  echo "|name|description|"
  echo "|---|---|"
  echo "$RESULTS"
  echo
fi

WORKSPACES=$(yq '.spec.workspaces.[] | ("|" + .name + "|" + (.description // "" | sub("\n", " ")) + "|" + (.optional // "false") + "|")' $TASK)
if [ -n "$WORKSPACES" ]; then
  echo "## Workspaces"
  echo "|name|description|optional|"
  echo "|---|---|---|"
  echo "$WORKSPACES"
fi

