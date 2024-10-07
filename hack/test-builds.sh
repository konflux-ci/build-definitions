#!/bin/bash -e

# Script for execution of the pipelines as Application Service

SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

TASKSDIR=${SCRIPTDIR}/../task

for task in $(ls $TASKSDIR); do
  VERSIONDIR=$(ls -d $TASKSDIR/$task/*/ | sort -t. -k 1,1n -k 2,2n -k 3,3n -k 4,4n | tail -n1)
  if [ -f $VERSIONDIR/$task.yaml ]; then
    oc apply -f $VERSIONDIR/$task.yaml
  elif [ -f $VERSIONDIR/kustomization.yaml ]; then
    oc apply -k $VERSIONDIR
  else
    echo Unable to apply task in $VERSIONDIR
  fi
done

oc apply -k $SCRIPTDIR/../pipelines/ -o yaml --dry-run=client | \
  yq e 'del(.items.[] | .spec.tasks.[] | .taskRef.version, .items.[] | .spec.finally.[] | .taskRef.version)' | \
  oc apply -f-

bash -c "$(curl -fsSL https://raw.githubusercontent.com/redhat-appstudio/infra-deployments/main/hack/build/setup-namespace.sh)"

[ "$1" == "skip_checks" ] && export SKIP_CHECKS=1
$SCRIPTDIR/test-build.sh https://github.com/jduimovich/single-container-app docker-build
$SCRIPTDIR/test-build.sh https://github.com/Michkov/simple-fbc fbc-builder
