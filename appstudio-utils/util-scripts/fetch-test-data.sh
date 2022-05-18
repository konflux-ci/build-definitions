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
for tr in $( pr-get-tr-names $PR_NAME ); do
  echo "searching pr: ${PR_NAME}"
  data=$( tr-get-result $tr $TEST_NAME )
  if [[ ! -z "${data}" ]]; then
      echo "have data: ${data}"
      result_found=1
      data_file=$( json-data-file test "$tr")
      echo "$data_file"
      json-merge-with-key $data "$data_file" "test" "$tr"
  fi
done

echo "done"

if [[ -z $result_found ]]; then
  # let's put an an empty hash here to express the the idea
  # that we looked for test results and found none
  echo '{}' > $( json-data-file test )
fi

show-data
