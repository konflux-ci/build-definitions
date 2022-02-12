#!/usr/bin/env bash  
 echo "Removing Unused Build Directories" 
# GC algorithm
# mark all build directories unused 
# rm unused marker in live pipeline-runs
# rm all directories with unused marker 
# all other directories are live and have no marker (done)
# if a directory is being gc'd by two copies of this task
# the marker will be unique so they can both run.
# live directories will be a noop
# dead directories can be deleted by either copy
# note, not recommended to run in parallel but will work. 

# use a unique marker per tasks based on time to NS
MARKER=.appstudio-mark-unused-$(date +"%Y%m%d%H%M%S%6N") 
# Keep track of the existing pvs, any pvs added during this run
# will be ignored until a later run so that new pvs which were not 
# originally marked dont get deleted due to not being marked. 
CANDIDATES=./pv-*

cd workspace/source 
echo "Cleanup:" 
BEFORE=$(du -s)
# mark all unused 
for build in $CANDIDATES ; do   
    if [ -d "$build" ]; then 
        echo "Directory: $build"
        echo "unused" > "$build/$MARKER"  
    else 
        if [ -f "$build" ]; then   
         echo "Warning - Some files prefixed with pv- $build"
        fi
    fi 
done 

kubectl get pipelineruns --no-headers -o custom-columns=":metadata.name" | \
    xargs -n 1 -I {} echo "Valid:" pv-{}  

# remove markers from live pipeline runs  
kubectl get pipelineruns --no-headers -o custom-columns=":metadata.name" | \
    xargs -n 1 -I {} rm -f pv-{}/$MARKER  2> /dev/null


# if still marked unused, may be removed
for build in $CANDIDATES ; do 
    if [ -f "$build/$MARKER" ]; then
        echo "Removing: $(du -h $build | tail -n 1)" 
        rm -rf $build 
    else
        if [ -d "$build" ]; then   
            echo "Keeping: $(du -h $build | tail -n 1)" 
        fi
    fi 
done
AFTER=$(du -s)

CMD=$(basename $0)
if [ -d "$1" ]; then 
    echo "$CMD Before: $BEFORE After: $AFTER" 
    echo "$CMD Before: $BEFORE After: $AFTER" > $1/status  
else
    echo "$CMD Before: $BEFORE After: $AFTER" 
fi 