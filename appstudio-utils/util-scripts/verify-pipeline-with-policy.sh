#!/bin/bash
#
# Verifies the given pipeline file passes the given rego policy
# usage:
#   verify-pipeline-with-policy.sh <pipeline file> <output file> <passed file>
# where:
#   <pipeline file> file containing the pipeline to be verified
#   <output file>  where to store the result in JSON format
#   <passed file>  where to store the overall passing result

set -euo pipefail

input_file="$1"
output="$2"
passed="$3"

# A tekton pipeline is a collection of tasks that you define and arrange in
# a specific order of execution as part of your continuous execution flow.
# Each task in a pipeline executes in a pod on your kubernetes cluster. You
# can configure various execution conditions to fit your business needs.
# 
# See https://tekton.dev/docs/pipelines/pipelines/#pipelines for more details
# including Required and Optional fields.

cd $(dirname $0)
source lib/fetch.sh

# TODO: If git clone fails, the task does not fail - fix that!
./fetch-ec-policies.sh

title Fetching config
save-policy-config

title Config
cat $DATA_DIR/config.json

title Pipeline
cat $input_file

title Results
./check-ec-policy.sh | tee "${output}"

title "Passed?"
./ec-pass-faill.sh "${output}" | tee "${passed}"

# If strict mode is enabled, fail the script (and the task)  when the policy check fails.
# Otherwise, complete successfully.
if [[ "${STRICT_POLICY:-'1'}" == "1" ]]; then
    [[ "$(cat ${passed})" == "true" ]]
fi
