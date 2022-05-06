
# Determine useful directories
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  # For hacking/testing
  ROOT_DIR=$( git rev-parse --show-toplevel )
else
  # For inside the container
  ROOT_DIR=
fi

SCRIPTS_DIR="$ROOT_DIR/appstudio-utils/util-scripts"
LIB_DIR="$SCRIPTS_DIR/lib"

# For these you can set the env vars to use non-default values
EC_WORK_DIR=${EC_WORK_DIR:-/tmp/ecwork}

DATA_DIR=${DATA_DIR:-"$EC_WORK_DIR/data"}
POLICIES_DIR=${POLICIES_DIR:-"$EC_WORK_DIR/policies"}
INPUT_DIR=${INPUT_DIR:-"$EC_WORK_DIR/input"}
mkdir -p $DATA_DIR
mkdir -p $POLICIES_DIR
mkdir -p $INPUT_DIR

POLICY_REPO=${POLICY_REPO:-"https://github.com/hacbs-contract/ec-policies.git"}
POLICY_REPO_REF=${POLICY_REPO_REF:-"main"}

# Helper functions for fetching stuff
source $LIB_DIR/title.sh
source $LIB_DIR/fetch/data.sh
source $LIB_DIR/fetch/git.sh
source $LIB_DIR/fetch/rekor.sh
source $LIB_DIR/fetch/cluster.sh
source $LIB_DIR/fetch/tekton.sh
