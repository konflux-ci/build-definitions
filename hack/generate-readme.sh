#!/bin/bash

RESOURCE=$1
if [ ! -f "$RESOURCE" ]; then
  echo "Usage: $0 \$PATH_TO_TASK_OR_STEPACTION"
  exit 1
fi
echo "# $(yq '.metadata.name' $RESOURCE) $(yq '.kind | downcase' $RESOURCE)"
echo
yq '.spec.description' $RESOURCE
echo

if [[ $(yq '.spec.params | length' "$RESOURCE") -gt 0 ]]; then
  PARAMS=$(yq '
      .spec.params.[] |
      with(select(.default | type == "!!seq"); .default = (.default | tojson(0))) |
      (
          "|" + .name +
          "|" + (.description // "" | sub("\n", " ")) +
          "|" + (.default // (.default != "*" | "")) +
          "|" + (.default != "*") + "|"
      )' $RESOURCE
  )

  echo "## Parameters"
  echo "|name|description|default value|required|"
  echo "|---|---|---|---|"
  echo "$PARAMS" | sed 's/||false|$/|""|false|/'
  echo
fi

if [[ $(yq '.spec.results | length' "$RESOURCE") -gt 0 ]]; then
  RESULTS=$(yq '.spec.results.[] | ("|" + .name + "|" + (.description // "" | sub("\n", " ")) + "|")' $RESOURCE)

  echo "## Results"
  echo "|name|description|"
  echo "|---|---|"
  echo "$RESULTS"
  echo
fi

if [[ $(yq '.spec.workspaces | length' "$RESOURCE") -gt 0 ]]; then
  WORKSPACES=$(yq '.spec.workspaces.[] | ("|" + .name + "|" + (.description // "" | sub("\n", " ")) + "|" + (.optional // "false") + "|")' $RESOURCE)

  echo "## Workspaces"
  echo "|name|description|optional|"
  echo "|---|---|---|"
  echo "$WORKSPACES"
fi

