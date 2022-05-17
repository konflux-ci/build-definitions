#!/usr/bin/env bash

set -euo pipefail

source $(dirname ${BASH_SOURCE[0]})/lib/fetch.sh

# When included from shellspec we don't want to invoke the code below
${__SOURCED__:+return}

if [[ "$#" -ne 2 ]]; then
  echo "Wrong number of arguments passed."
  echo "Usage ./fetch-test-data.sh <PipelineRunName> <TestResultName>"
  exit 1
fi

PR_NAME=$1
TEST_NAME=$2

# search all task runs in a pipeline
# write output in format $basdir/data/test/$task_name/data.json
result_found=
for tr in $( pr_get_tr_names $PR_NAME ); do
  data=$( tr_get_result $tr $TEST_NAME )
  if [[ ! -z "${data}" ]]; then
      result_found=1
      task_name=$( tr_get_task_name ${tr} )
      echo "${data}" | jq > $( json_data_file test ${task_name} )
  fi
done

if [[ -z $result_found ]]; then
  # let's put an an empty hash here to express the the idea
  # that we looked for test results and found none
  echo '{}' > $( json_data_file test )
fi

show_data
