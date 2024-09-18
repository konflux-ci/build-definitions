#!/bin/bash

set -ex

cd $(git rev-parse --show-toplevel)
source test/common.sh

if [[ -z ${@} || ${1} == "-h" ]];then
    cat <<EOF
This script will run a single task to help developers testing directly a
single task without sending it to CI.

You need to specify the resource kind as the first argument, resource name 
as the second argument and the resource version as the second argument.

For example :

${0} task git-clone 0.1

will run the tests for the git-clone task

while

${0} stepaction git-clone 0.1

will run the tests for the git-clone stepaction.

EOF
    exit 0
fi

TMPF=$(mktemp /tmp/.mm.XXXXXX)
clean() { rm -f ${TMPF}; }
trap clean EXIT

RESOURCE=${1}
NAME=${2}
VERSION=${3}

resourcedir=${RESOURCE}/${NAME}/${VERSION}

if [[ ! -d ${resourcedir}/tests ]];then
    echo "No 'tests' directory is located in ${resourcedir}"
    exit 1
fi

tns=${NAME}-${VERSION//./-}

# Delete the tns if already exists
${KUBECTL_CMD} delete ns ${tns} >/dev/null 2>/dev/null || :

${KUBECTL_CMD} create namespace ${tns}

#create appstudio-pipeline SA in the test namespace if not already
if ! ${KUBECTL_CMD} get sa appstudio-pipeline -n ${tns} | grep 'appstudio-pipeline'; then
   $KUBECTL_CMD create sa appstudio-pipeline -n ${tns}
fi

test_resource_creation ${RESOURCE}/${NAME}/${VERSION}/tests