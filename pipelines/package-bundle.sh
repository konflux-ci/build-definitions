#!/bin/bash
SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

TEMPLATES=$SCRIPTDIR/build-templates-bundle

REPO_USER=$MY_QUAY_USER
if [  -z "$REPO_USER" ]; then
    REPO_USER=$(git config --get remote.origin.url | cut -d '/' -f 4)  
fi 
if [ "$REPO_USER" = "redhat-appstudio" ]; then
    echo "Warning: You are updating the default bundle in redhat-appstudio" 
    echo "This is disabled unless you pass -confirm on the cmdline"
    if ["$1" = "-confirm"]; then 
        echo "Using $REPO_USER to create OCI Bundle "
    else 
        echo "Cannot push to redhat-appstudio without a -confirm on command line."
        exit 1
    fi 
fi 
BUNDLE=quay.io/$REPO_USER/build-templates-bundle:v0.1

echo 
echo "Package Templates from: $SCRIPTDIR/build-templates-bundle"
echo "Using $REPO_USER to create OCI Bundle (set MY_QUAY_USER to override) " 
echo "Building $BUNDLE" 
echo 
 
PARAMS="" 
for i in $TEMPLATES/*.yaml ; do   
    PARAMS="$PARAMS -f $i " 
done 
tkn bundle push $BUNDLE $PARAMS  
echo  
 


  