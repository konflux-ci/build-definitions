#!/usr/bin/bash
set -euo pipefail

#
# Fetch data about a pipeline run for use by the enterprise
# contract policy checker.
#
# The one argument is the name of a pipeline run. If that isn't
# provided it will default to the most recent pipeline run.
#
# Note: This script assumes we have access to the cluster
# where the pipeline run is, and the pipelinerun data itself
# which is not likely to be the case in the future.
#
# See also tasks/enterprise-contract.yaml
#
source $(dirname $0)/lib/fetch.sh

# Pipeline run name
PR_NAME=${1:-$( tkn pr describe --last -o name )}
PR_NAME=$( echo "$PR_NAME" | sed 's|.*/||' )

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
  # - image signatures from the container registry using cosign
  # - image attestations from the container registry using cosign
  # - tekton-results probably
done

title "Data files"
show-data
