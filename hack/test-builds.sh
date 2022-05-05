#!/bin/bash -e

# Script for execution of the pipelines as Application Service

SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

oc apply -k $SCRIPTDIR/test-build
if [ "$1" == "" ]; then
  oc apply -k $SCRIPTDIR/../pipelines/base
else
  oc apply -k $SCRIPTDIR/../pipelines/$1
fi

$SCRIPTDIR/test-build.sh https://github.com/jduimovich/spring-petclinic java-builder
$SCRIPTDIR/test-build.sh https://github.com/jduimovich/single-nodejs-app nodejs-builder
$SCRIPTDIR/test-build.sh https://github.com/jduimovich/single-container-app docker-build
