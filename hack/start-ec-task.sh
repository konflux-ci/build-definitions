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
#  * Make sure you have at least one pipeline run in your cluster.
#
#  * (Optional) Modify the POLICY_REPO and POLICY_REPO_REF params below as required.
#
#  * Run this script:
#      ./start-ec-task.sh
#
#    To run it against a different pipeline run:
#      ./start-ec-task.sh <pipeline-run-name>
#

PR_NAME=${1:-$( tkn pr describe --last -o name )}
PR_NAME=$( echo "$PR_NAME" | sed 's|.*/||' )
GIT_SHA=$( git rev-parse HEAD )

#
# Actually these only need to be created once.
#
# Todo:
# - Move these to an appropriate location, probably
#   in the infra-deployments gitops config
# - Review what the access requirments are and narrow
#   down the permissiveness to only what is needed
#
echo "
apiVersion: v1
kind: ServiceAccount
metadata:
  name: enterprise-contract-sa
---
# TODO: Reduce these permissions
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: enterprise-contract
rules:
- apiGroups:
  - 'tekton.dev'
  resources:
  - '*'
  verbs:
  - '*'
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: enterprise-contract
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: enterprise-contract
subjects:
- kind: ServiceAccount
  name: enterprise-contract
  namespace: tekton-chains

" | oc apply -f -

#
# Determine which bundle we should use
#
# Todo:
# - How to discover BUNDLE_NUMBER so it isn't hard coded?
# - Make this generally more robust
# - Make sure it works if the local namespace *doesn't* have
#   build-pipelines-defaults cm
#
DEFAULT_BUNDLE=$(
  # ./build-and-push.sh creates this cm in the current project
  # and iiuc it overrides the default in `-n build-templates`
  oc get cm build-pipelines-defaults --output=jsonpath='{.data.default_build_bundle}' )
BUNDLE_NUMBER=1
USE_BUNDLE="$(
  echo "$DEFAULT_BUNDLE" | sed 's/build-templates-bundle/appstudio-tasks/' )-$BUNDLE_NUMBER"
echo "Using bundle $USE_BUNDLE for task"

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
  generateName: enterprise-contract-
spec:
  taskRef:
    name: enterprise-contract
    bundle: $USE_BUNDLE
  params:
    - name: PIPELINE_RUN_NAME
      value: $PR_NAME

    # Modify these defaults as required
    #- name: POLICY_REPO
    #  value: https://github.com/hacbs-contract/ec-policies.git
    #- name: POLICY_REPO_REF
    #  value: main

  # Todo: Not sure if we need this secret
  workspaces:
    - name: sslcertdir
      secret:
        secretName: chains-ca-cert
" | oc create -f -

#
# Watch the taskrun that was created
#
tkn tr logs -f $( tkn tr describe --last -o name | sed 's|.*/||' )
