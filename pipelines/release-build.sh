#!/bin/bash
SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

TEMPLATES=$SCRIPTDIR/build-templates-bundle
BUNDLE=quay.io/redhat-appstudio/build-templates-bundle:v0.1.3
# TODO for CI 
# IMAGE_FULL_TAG=$(git ls-remote $GITREPO HEAD)
# IMAGE_SHORT_TAG=${IMAGE_FULL_TAG:position:7}

echo "Warning: You are updating the default bundle in redhat-appstudio" 
echo "This is disabled unless you pass -confirm on the cmdline"
if [ "$1" = "-confirm" ]; then 
    echo "Creating Release $BUNDLE "
else 
    echo "Cannot push to redhat-appstudio without a -confirm on command line."
    exit 1 
fi 
$SCRIPTDIR/util-package-bundle.sh $BUNDLE
 


  