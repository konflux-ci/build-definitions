
#!/usr/bin/env bash   
# you can test this script inside or outside tekton
# you need to pass a url (param1) and destination directory (param2) if running on shell
# or /tekton/results if running in tekton
echo "Image: $1"    
DIGEST=$(skopeo inspect "docker://$1" 2> err | jq '.Digest')
if [ -z "$DIGEST" ]
then
  echo "Exists: false"    
  echo -n "false" >  $2/exists 
else 
  echo "Exists: true"    
  echo -n "true" >  $2/exists
fi     
 