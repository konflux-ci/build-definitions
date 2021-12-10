#!/usr/bin/env bash
# you can test this script inside or outside tekton
# you need to pass a destination directory if running on shell
# or /tekton/results if running in tekton

cd ./workspace/source 
yq e '.components | with_entries(select(.[].name=="outerloop-build"))' devfile.yaml |  yq e '.[]' - > tmp.outerloop-build.yaml
echo
echo "outerloop-build section of devfile."
echo "-----------------------------------"
cat tmp.outerloop-build.yaml 
yq e '.components | with_entries(select(.[].name=="outerloop-deploy"))' devfile.yaml| yq e '.[]' - > tmp.outerloop-deploy.yaml
echo "---"
echo
echo "outerloop-deploy section of devfile."
echo "------------------------------------"
cat tmp.outerloop-deploy.yaml 
echo "---"
echo 

DOCKERFILE="$(yq e '.image.dockerfile.uri' tmp.outerloop-build.yaml)"
BC="$(yq e '.image.dockerfile.buildContext' tmp.outerloop-build.yaml)"
DEPLOYFILE="$(yq e '.kubernetes.uri' tmp.outerloop-deploy.yaml)"

echo "Devfile Analysis:"
echo "Dockerfile: $DOCKERFILE"  
echo "BuildContext: $BC"   
echo "Deploy: $DEPLOYFILE"
echo   
echo "Deploy contents:"
cat "$DEPLOYFILE"
echo   
  
echo -n "$DOCKERFILE" >  $1/dockerfile  
echo -n "$BC" > $1/path
echo -n "$DEPLOYFILE" > $1/deploy

  
  