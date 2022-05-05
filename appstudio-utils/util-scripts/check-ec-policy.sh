#!/usr/bin/bash
set -euo pipefail

EC_WORK_DIR=${EC_WORK_DIR:-/tmp/ecwork}

DATA_DIR=$EC_WORK_DIR/data
INPUT_DIR=$EC_WORK_DIR/input
POLICY_DIR=$EC_WORK_DIR/policies

FORMAT=${1:-pretty}

OPA_QUERY=${OPA_QUERY:-data.hacbs.contract.main.deny}

[[ ! -d $DATA_DIR ]] && echo "Data dir $DATA_DIR not found!" && exit 1
[[ ! -d $INPUT_DIR ]] && echo "Input dir $INPUT_DIR not found!" && exit 1
[[ ! -d $POLICY_DIR ]] && echo "Policy dir $POLICY_DIR dir not found!" && exit 1

INPUT_FILES=$( find ${INPUT_DIR} -name input.json )

conftest $INPUT_FILES \
  --data $DATA_DIR \
  --data $POLICY_DIR \
  --format $FORMAT \
  --combine \
  --namespace $OPA_QUERY
