#!/usr/bin/bash
set -euo pipefail

source $(dirname $0)/lib/fetch.sh

# Ensure there's no stale data
clear-data

title "Fetching policy config"
save-policy-config

title "Fetching chains config"
k8s-save-data ConfigMap chains-config tekton-chains

title "Fetching pipeline run data for $PR_NAME"
k8s-save-data PipelineRun $PR_NAME

for tr in $( pr-get-tr-names $PR_NAME ); do
  k8s-save-data TaskRun $tr
  tr-save-transparency-log $tr
  tr-save-digest-logs $tr

  # Todo: Also fetch:
  # - task results from Kruno's testing tasks
  # - image signatures from the container registry
  # - image attestations from the container registry
  # - tekton-results probably
done

title "Data files"
show-data
