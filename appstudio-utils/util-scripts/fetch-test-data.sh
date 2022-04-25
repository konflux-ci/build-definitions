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
TEST_RESULT_NAME=$2

TEST_DATA_FILE="$DATA_DIR/test.json"
TOP_LEVEL_KEY=test

title "Fetching test results"

# intialize the file
echo "{\"$TOP_LEVEL_KEY\":{}}" | jq > "$TEST_DATA_FILE"

# search all task runs in a pipeline
# if test results are found they will be merged into the data file
for tr in $( pr-get-tr-names $PR_NAME ); do
  echo "checking ${tr}"
  data=$( tr-get-result "$tr" "$TEST_RESULT_NAME" )
  if [[ ! -z "${data}" ]]; then
    echo "...results found"
    json-merge-with-key "$data" "$TEST_DATA_FILE" $TOP_LEVEL_KEY "$tr"
  fi
done

title "Test results"
cat "$TEST_DATA_FILE"
