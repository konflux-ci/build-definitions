#!/bin/bash
SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

oc apply -k $SCRIPTDIR/test-all-tasks
tkn pipeline start test-all-tasks -w name=workspace,claimName=app-studio-default-workspace -p test-image=quay.io/redhat-appstudio/appstudio-utils:test --showlog --use-param-defaults

# cleanup manually, this is so you can inspect the results 
# if you delete immediately, the results are gone
#oc delete -f util-tasks/
#oc delete pipeline test-all-tasks
