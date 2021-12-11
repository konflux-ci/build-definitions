#!/bin/bash
SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

TEMPLATES=$SCRIPTDIR/build-templates-bundle
BUNDLE=$1
if [  -z "$BUNDLE" ]; then 
    echo "No Bundle Name"
    exit 1 
fi   
echo 
echo "Package Templates from: $SCRIPTDIR/build-templates-bundle"  
echo "Building $BUNDLE" 
echo 
 
PARAMS="" 
for i in $TEMPLATES/*.yaml ; do   
    PARAMS="$PARAMS -f $i " 
done 
tkn bundle push $BUNDLE $PARAMS  
echo  
 


  