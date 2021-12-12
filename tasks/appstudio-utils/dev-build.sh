# local build script

# to prevent forks from accidentally pushing to redhat-appstudio
# do no allow even authorized users to accidentally use this script to do so. 
REPO_USER=$(git config --get remote.origin.url | cut -d '/' -f 4) 
if [ "$REPO_USER" = "redhat-appstudio" ]; then
    echo "Using redhat-appstudio quay.io user to push results "
    docker build -t quay.io/redhat-appstudio/appstudio-utils:v0.1 .
    docker push quay.io/redhat-appstudio/appstudio-utils:v0.1 
    exit 0 
fi 
if [  -z "$MY_QUAY_USER" ]; then
    echo "MY_QUAY_USER is not set, skip this build."
    exit 0
fi 
BUILD_TAG=$(date +"%Y-%m-%d-%H%M%S") 
IMG="quay.io/$MY_QUAY_USER/appstudio-utils:$BUILD_TAG"
echo "Using $MY_QUAY_USER to push results "
docker build -t $IMG .
docker push $IMG

for TASK in util-tasks/*.yaml ; do
    echo $TASK
    cat $TASK | 
        yq -M e ".spec.steps[0].image=\"$IMG\"" - | \
        oc apply -f - 
done 



 

 
 