#!/usr/bin/bash
set -xeuo pipefail

EC_WORK_DIR=${EC_WORK_DIR:-/tmp/ecwork}

DATA_DIR=$EC_WORK_DIR/data
INPUT_DIR=$EC_WORK_DIR/input
POLICY_DIR=$EC_WORK_DIR/policies

FORMAT=${1:-pretty}

OPA_QUERY=${OPA_QUERY:-hacbs.contract.main}

[[ ! -d $DATA_DIR ]] && echo "Data dir $DATA_DIR not found!" && exit 1
[[ ! -d $INPUT_DIR ]] && echo "Input dir $INPUT_DIR not found!" && exit 1
[[ ! -d $POLICY_DIR ]] && echo "Policy dir $POLICY_DIR dir not found!" && exit 1

INPUT_FILES=$( find ${INPUT_DIR} -name input.json )
echo "policy dir"
ls $POLICY_DIR/policies

conftest test $INPUT_FILES \
  --data $DATA_DIR \
  --policy $POLICY_DIR \
  --combine \
  --namespace $OPA_QUERY
