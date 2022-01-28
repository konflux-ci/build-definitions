#!/bin/bash
SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

TEMPLATES=$SCRIPTDIR/build-templates-bundle
BUNDLE=$1
if [  -z "$BUNDLE" ]; then 
    echo "No Bundle Name"
    exit 1 
fi
export TAG=$(echo $BUNDLE | sed "s/^.*://")
export CONTAINER_REPO=$(dirname $BUNDLE)
echo 
echo "Package Templates from: $TEMPLATES"  
echo "Building $BUNDLE" 
echo 
 
PARAMS=""
TMP_DIR=$(mktemp -d)
for file in $TEMPLATES/*.yaml; do
    BASENAME=$(basename $file)
    envsubst < $file > ${TMP_DIR}/$BASENAME
    PARAMS="$PARAMS -f ${TMP_DIR}/$BASENAME "
done
tkn bundle push $BUNDLE $PARAMS  
rm -rf ${TPM_DIR}
echo  
