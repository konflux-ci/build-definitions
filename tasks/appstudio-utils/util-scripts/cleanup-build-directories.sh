#!/usr/bin/env bash  
echo "Removing Unused Build Directories"
# GC algorithm
# mark all build directories unused 
# rm unused marker in live pipeline-runs
# rm all directories with unused marker 
# all other directories are live and have no marker (done)
 
MARKER=.appstudio-mark-unused 
 
cd workspace/source 
echo "Cleanup:" 
BEFORE=$(du -h . | tail -n 1)
# mark all unused 
for build in ./pv-* ; do   
    if [ -d "$build" ]; then
        echo "Directory: $build"
        echo "unused" > "$build/$MARKER"  
    elif [ -f "$build" ]; then
        echo "Warning - Some files prefixed with pv- $build"
    fi 
done 

kubectl get pipelineruns --no-headers -o custom-columns=":metadata.name" | \
    xargs -n 1 -I {} echo "Valid:" pv-{}  

# remove markers from live pipeline runs  
kubectl get pipelineruns --no-headers -o custom-columns=":metadata.name" | \
    xargs -n 1 -I {} rm -f pv-{}/$MARKER  2> /dev/null

# if still marked unused, may be removed
for build in ./pv-* ; do 
    if [ -f "$build/$MARKER" ]; then
        echo "Removing: $(du -hs $build)"
        rm -rf $build 
    elif [ -d "$build" ]; then
        echo "Keeping: $(du -hs $build)"
    fi 
done
AFTER=$(du -hs .)

CMD=$(basename $0)
if [ -d "$1" ]; then
    echo "$CMD Before: $BEFORE After: $AFTER" 
    echo "$CMD Before: $BEFORE After: $AFTER" > $1/status  
else
    echo "$CMD Before: $BEFORE After: $AFTER" 
fi
