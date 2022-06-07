#!/usr/bin/env bash
set -ue
#
# Use the policies defined in the Enterprise Contract to validate a
# pipeline definition.
#
# Typical usage:
#   $ oc get pipeline somePipeline -n someNamespace -o json > pipeline.json
#   $ ./verify-pipeline.sh pipeline.json
#
if [ $# -ge 1 ] && [ -n "$1" ]; then
  INPUT_FILE=$1
else
  echo "Please specify an input file containing a pipeline definition in json or yaml format."
  exit 1
fi

ROOT_DIR=$( git rev-parse --show-toplevel )
SCRIPTS_DIR="$ROOT_DIR/appstudio-utils/util-scripts"

# For these you can set the env vars to use non-default values
EC_WORK_DIR=${EC_WORK_DIR:-/tmp/ecwork}
POLICIES_DIR=${POLICIES_DIR:-"$EC_WORK_DIR/policies"}
POLICY_REPO=${POLICY_REPO:-"https://github.com/hacbs-contract/ec-policies.git"}
POLICY_REPO_REF=${POLICY_REPO_REF:-"main"}
DATA_DIR=${DATA_DIR:-"$EC_WORK_DIR/data"}

# This produces a bunch of output that we don't particularly care about here,
# hence the redirect to /dev/null.
# (This will all be replaced with an ec command in the near future, so don't
# worry about it too much.)
mkdir -p $POLICIES_DIR > /dev/null
$SCRIPTS_DIR/fetch-ec-policies.sh >/dev/null 2>&1

# Workaround a bug that causes future warnings to become denies if this isn't present
echo '{"config":{}}' > $DATA_DIR/data.json

echo "# Input file: $INPUT_FILE"
echo "# Pipeline name: $( yq e .metadata.name $INPUT_FILE )"
echo "# Policy repo: $POLICY_REPO"
echo "# Git ref: $POLICY_REPO_REF"

# Execute our conftest to validate our resource against our policy
conftest test $INPUT_FILE \
  --data $DATA_DIR \
  --policy $POLICIES_DIR/policy \
  --namespace pipeline.main \
  --output json \
  --no-fail

# Cleanup our created directories
# Comment this out if you need to debug.
rm -rf $EC_WORK_DIR
