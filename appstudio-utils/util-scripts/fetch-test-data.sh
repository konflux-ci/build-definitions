#!/usr/bin/env bash

set -euo pipefail

if [[ "$#" -ne 2 ]]; then
  echo "Wrong number of arguments passed."
  echo "Usage ./fetch-test-data.sh <PipelineRunName> <TestResultName>"
  exit 1
fi

PR_NAME=$1
TEST_NAME=$2

source $(dirname $0)/lib/fetch.sh

# search all task runs in a pipeline
# write output in format $basdir/data/test/$task_name/data.json
for tr in $( pr-get-tr-names $PR_NAME ); do
  data=$( tr-get-result $tr $TEST_NAME )
  if [[ ! -z "${data}" ]]; then
      task_name=$( tr-get-task-name ${tr} )
      echo "${data}" | jq > $( json-data-file test ${task_name} )
  fi
done

show-data
