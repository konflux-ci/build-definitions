#!/usr/bin/bash
set -euo pipefail

EC_WORK_DIR=${EC_WORK_DIR:-/tmp/ecwork}

DATA_DIR=$EC_WORK_DIR/data
POLICY_DIR=$EC_WORK_DIR/policies
INPUT_DIR=$EC_WORK_DIR/input
INPUT_FILE=$INPUT_DIR/input.json

CONFTEST_NAMESPACE=${CONFTEST_NAMESPACE:-release.main}

[[ ! -d $DATA_DIR ]] && echo "Data dir $DATA_DIR not found!" && exit 1
[[ ! -d $POLICY_DIR ]] && echo "Policy dir $POLICY_DIR dir not found!" && exit 1
[[ ! -d $INPUT_DIR ]] && echo "Input dir $INPUT_DIR not found!" && exit 1
[[ ! -f $INPUT_FILE ]] && echo "Input file $INPUT_FILE not found!" && exit 1

conftest test $INPUT_FILE \
  --data $DATA_DIR \
  --policy $POLICY_DIR/policy \
  --namespace $CONFTEST_NAMESPACE \
  --output json \
  --no-fail
