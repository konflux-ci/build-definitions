#
#
# Misc utilties for bash scripted demos
#
# Typical usage:
#   source $(dirname $0)/_helpers.sh

#------------------------------------------------

#
# Cosign knows how to fetch the key from the secret in the cluster.
# Requires that you're authenticated with an account that can access
# the signing-secret, i.e. kubeadmin but not developer.
#
K8S_SIG_KEY=k8s://tekton-chains/signing-secrets

# Presumably real public keys can be published somewhere in future
#PUB_SIG_KEY=?

# For now use this by default
[[ -z $SIG_KEY ]] && SIG_KEY=$K8S_SIG_KEY


#------------------------------------------------

#
# Support running demos quietly or without pauses
#
QUIET=
FAST=
for arg in "$@"; do
  #
  #
  if [[ $arg == "--quiet" ]]; then
    QUIET=1
    FAST=1
  fi

  if [[ $arg == "--fast" ]]; then
    FAST=1
  fi
done

#
# Create a pretty heading
#
title() {
  [[ -n $QUIET ]] && return

  echo
  echo "🔗 ---- $* ----"
}

#
# Quiet aware echo
#
say() {
  [[ -n $QUIET ]] && return

  echo $*
}

#
# Pause and wait for user to hit enter
#
pause() {
  [[ -n $QUIET ]] || [[ -n $FAST ]] && return

  echo
  local MSG="$*"
  [[ -z "$MSG" ]] && MSG="Hit enter to continue..."
  read -p "$MSG"
}

#
# Show a command then run it after user hits enter
# (Could use set -x instead I guess.)
#
show-then-run() {
  if [[ -z "${KUBERNETES_SERVICE_HOST}" ]]; then
    [[ -z $QUIET ]] && [[ -z $FAST ]] && read -p "\$ $*"
    $*
  else
   $1
  fi
}


#------------------------------------------------

#
# Pretty print json as yaml
#
yq-pretty() {
  yq -P -C e ${1:-} -
}

#
# Fetch json with curl
#
curl-json() {
  curl -s -H "Accept: application/json" $@
}

#
# Trim the type prefix from a k8s name
#
trim-name() {
  echo "$1" | sed 's#.*/##'
}

# Helper for jsonpath
get-jsonpath() {
  kubectl get $TASKRUN_NAME -o jsonpath={.$1}
}

# Helper for reading chains values
get-chainsval() {
  get-jsonpath metadata.annotations.chains\\.tekton\\.dev/$1
}

# Helper for reading a task result
get-taskresult() {
  kubectl get $TASKRUN_NAME \
    -o jsonpath="{.status.taskResults[?(@.name == \"$1\")].value}"
}

# Helper for reading a resources result
get-resourcesresult() {
  kubectl get $TASKRUN_NAME \
    -o jsonpath="{.status.resourcesResult[?(@.key == \"$1\")].value}"
}

# helper to check if running in kubernetes.
# If running in kubernetes, we don't want to pause
check-pause() {
  ARG=${1:-""}
  if [[ -z "${KUBERNETES_SERVICE_HOST}" ]]; then
    pause $ARG
  else
    $ARG
  fi
}

cosign-verify() {
  IMAGE_URL=$1
  SIG_KEY=$2
  VERBOSE=${3:-""}
  set -x
  COSIGN_EXPERIMENTAL=1 cosign verify $VERBOSE --key $SIG_KEY $IMAGE_URL -o json | jq .
}

cosign-verify-attestation() {
  IMAGE_URL=$1
  SIG_KEY=$2

  cosign verify-attestation --key $SIG_KEY $IMAGE_URL --output-file /tmp/verify-att.out
  # There can be multiple attestations for some reason and hence multiple lines in
  # this file, which makes it invalid json. For the sake of the demo we'll ignore
  # all but the last line.
  tail -1 /tmp/verify-att.out | yq e . -P -
}

kaniko-cosign-verify() {
  TASKRUN_NAME=$1
  IMAGE_URL=$2
  SIG_KEY=$3

  title "Inspect $TASKRUN_NAME annotations"
  # Just want to show the chains related fields
  oc get $TASKRUN_NAME -o yaml | yq-pretty .metadata.annotations
  check-pause

  title "Image url from task result"
  kubectl get $TASKRUN_NAME -o jsonpath="{.status.taskResults[?(@.name == \"IMAGE_URL\")].value}"

  title "Image digest from task result"
  kubectl get $TASKRUN_NAME -o jsonpath="{.status.taskResults[?(@.name == \"IMAGE_DIGEST\")].value}"
  echo

  title "Cosign verify the image"
  # Save the output data to a file so we can look at it later
  # (Actually we could just pipe it to jq because the text goes to stderr I think..?)
  show-then-run "cosign-verify $IMAGE_URL $SIG_KEY"

  check-pause

  title "Cosign verify the image's attestation"
  show-then-run "cosign-verify-attestation $IMAGE_URL $SIG_KEY"
  check-pause

  title "Inspect the payload from that attestation output"
  tail -1 /tmp/verify-att.out | yq e .payload - | base64 -d | yq e . -P -

}
