#!/usr/bin/bash
set -euo pipefail

EC_WORK_DIR=${EC_WORK_DIR:-/tmp/ecwork}

DATA_DIR=$EC_WORK_DIR/data
POLICY_DIR=$EC_WORK_DIR/policies

FORMAT=${1:-pretty}

OPA_QUERY=${OPA_QUERY:-data.hacbs.contract.main.deny}

[[ ! -d $DATA_DIR ]] && echo "Data dir $DATA_DIR not found!" && exit 1
[[ ! -d $POLICY_DIR ]] && echo "Policy dir $POLICY_DIR dir not found!" && exit 1

opa eval \
  --data $DATA_DIR \
  --data $POLICY_DIR \
  --format $FORMAT \
  $OPA_QUERY
