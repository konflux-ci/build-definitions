#!/usr/bin/env bash
#
# A wrapper for cosign to help verify a signed image
#

# Required
IMAGE_URL=$1

# Set this to use a different sig key. See below for the defaults.
SIG_KEY=$COSIGN_SIG_KEY

# Set this to --verbose for lots of cosign debug output
VERBOSE=$COSIGN_VERBOSE

set -eu

if [[ -z $IMAGE_URL ]]; then
  echo "Image url is required."
  exit 1
fi

if [[ -z $SIG_KEY ]]; then
  # Requires that you're authenticated with an account that can access
  # the signing-secret in the cluster, i.e. kubeadmin but not developer
  SIG_KEY=k8s://tekton-chains/signing-secrets

  # If you have the public key locally because you created it
  # (Presumably real public keys will published somewhere in future)
  #SIG_KEY=$(git rev-parse --show-toplevel)/cosign.pub
fi

source $(dirname $0)/_helpers.sh

cosign-verify $IMAGE_URL $SIG_KEY $VERBOSE
