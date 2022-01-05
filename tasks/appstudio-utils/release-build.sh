# local build script

BUILD_TAG=v0.1.2
IMG="quay.io/redhat-appstudio/appstudio-utils:$BUILD_TAG"

echo "Warning: You are updating an image in redhat-appstudio" 
echo "This is disabled unless you pass -confirm on the cmdline"
if [ "$1" = "-confirm" ]; then 
    echo "Creating Release $IMG "
    echo "Using redhat-appstudio quay.io user to push results "
    echo "The tasks in util-tasks need to be updated to reference this tag "
    echo "The gitops repo for app studio needs to have ClusterTasks created for the tasks in util-task."
    docker build -t $IMG .
    docker push $IMG 
else 
    echo "Cannot push to redhat-appstudio without a -confirm on command line."
    exit 1 
fi 


 

 
 