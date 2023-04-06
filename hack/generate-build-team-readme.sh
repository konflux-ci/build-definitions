#!/bin/bash

for OWNERS_FILE in $(find task -name OWNERS); do
  if grep -q "Stonesoup Build Team" $OWNERS_FILE; then
    TASKDIR=$(dirname $OWNERS_FILE)
    TASK=$(basename $TASKDIR)
    VERSIONDIR=$(ls -d $TASKDIR/*/ | sort -t. -k 1,1n -k 2,2n -k 3,3n -k 4,4n | tail -n1)
    ./hack/generate-readme.sh $VERSIONDIR/$TASK.yaml > $VERSIONDIR/README.md
  fi
done
