#!/usr/bin/env bash
set -ue

# Use the policies defined in the Enterprise Contract to validate a 
# pipline definition
#
# Tyipcal usage:
#  oc get pipeline somePipeline -n someNamespace -o json > pipeline.json
#  ./verify_pipeline.sh pipeline.json

if [ $# -ge 1 ] && [ -n "$1" ]; then
  INPUT_FILE=$1
else
  echo "The path to a file to test must be specified"
  exit 1
fi

ROOT_DIR=$( git rev-parse --show-toplevel )

SCRIPTS_DIR="$ROOT_DIR/appstudio-utils/util-scripts"

# For these you can set the env vars to use non-default values
EC_WORK_DIR=${EC_WORK_DIR:-/tmp/ecwork}

POLICIES_DIR=${POLICIES_DIR:-"$EC_WORK_DIR/policies"}

mkdir -p $POLICIES_DIR

POLICY_REPO=${POLICY_REPO:-"https://github.com/hacbs-contract/ec-policies.git"}
POLICY_REPO_REF=${POLICY_REPO_REF:-"main"}

CONFTEST_NAMESPACE=${CONFTEST_NAMESPACE:-"pipeline.main"}

$SCRIPTS_DIR/fetch-ec-policies.sh

# Execute our conftest to validate our resource against
# our policy

conftest test $INPUT_FILE \
  --policy $POLICIES_DIR/policy \
  --namespace $CONFTEST_NAMESPACE \
  --output json \
  --no-fail

# Cleanup our created directories
# Comment this out if you need to debug.
rm -rf $EC_WORK_DIR
