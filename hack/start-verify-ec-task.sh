#!/usr/bin/bash
#
# Rough hacking guide:
#
#  * Commit your changes as required. (No need to push to GitHub.)
#
#  * Push a new base image and new task bundles like this:
#      env MY_QUAY_USER=$USER BUILD_TAG=$(git rev-parse HEAD) ./build-and-push.sh
#
#    (Assumes you have the required repos created in quay.io, you're signed in there with podman,
#    and your quay.io username matches $USER)
#
#  * Create a Secret in the current namespace containing the cosign.pub key. This should be a
#    partial copy of the Secret tekton-chains/signing-secrets. Only the public key should be
#    included in this Secret. By default the name of the Secret is 'cosign-public-key', set
#    the PUBLIC_KEY_SECRET environment variable to use a different name. For example:
#    oc -n tekton-chains get secret signing-secrets -o json | jq '.data."cosign.pub" | @base64d' -r > cosign.pub
#    oc create secret generic cosign-public-key --from-file=cosign.pub
#
#  * Make sure you have an image that has already been signed by Chains.
#
#  * (Optional) Modify the POLICY_REPO and POLICY_REPO_REF params below as required.
#
#  * Run this script:
#      ./start-verify-ec-task.sh <image-ref>
#    where <image-ref> is a valid image reference, e.g. quay.io/spam/bacon@sha256:...
#
#
# See also hack/chains/release-pipeline-with-ec-demo.sh in the infra-deployments repo
# for a more functional demo showing the EC task being used in a pipeline.
#
set -euo pipefail

IMAGE_REF="$1"

PUBLIC_KEY_SECRET="${PUBLIC_KEY_SECRET:-cosign-public-key}"

NAMESPACE="$(oc get sa default -o jsonpath='{.metadata.namespace}')"

#
# Determine which bundle we should use
#
# Todo:
# - How to discover BUNDLE_NUMBER so it isn't hard coded?
# - Make this generally more robust
#
DEFAULT_BUNDLE=$(
  # ./build-and-push.sh creates this cm in the current project
  # and iiuc it overrides the default in `-n build-templates`
  oc get cm build-pipelines-defaults --output=jsonpath='{.data.default_build_bundle}' )
BUNDLE_NUMBER=2
USE_BUNDLE="$(
  echo "$DEFAULT_BUNDLE" | sed 's/build-templates-bundle/appstudio-tasks/' )-$BUNDLE_NUMBER"
echo "Using bundle $USE_BUNDLE for task"

TASK_RUN_NAME="verify-enterprise-contract-$(openssl rand --hex 5)"

#
# Create the taskrun
#
# Todo:
# - Test it with the default bundle
# - Would it be nicer to use `tkn start`?
#
echo "apiVersion: tekton.dev/v1beta1
kind: TaskRun
metadata:
  name: $TASK_RUN_NAME
spec:
  taskRef:
    name: verify-enterprise-contract
    bundle: $USE_BUNDLE
  params:
    - name: IMAGE_REF
      value: $IMAGE_REF

    - name: PUBLIC_KEY
      value: k8s://$NAMESPACE/$PUBLIC_KEY_SECRET

    # Modify these defaults as required
    #- name: POLICY_REPO
    #  value: https://github.com/hacbs-contract/ec-policies.git
    #- name: POLICY_REPO_REF
    #  value: main
    #- name: STRICT_POLICY
    #  value: \"1\"

" | oc create -f -

#
# Watch the taskrun that was created
#
tkn tr logs -f $TASK_RUN_NAME
