# export-image-tar task

Given an input image save it as an oci-archive tar file, then push it as an oci artifact to a given output artifact location. This is useful for sharing images without the use of a registry, e.g. direct download.

## Parameters
|name|description|default value|required|
|---|---|---|---|
|input-image|The input image that is to be saved as an oci-archive tar file||true|
|tar-filename|The tar filename of the saved input image|image.tar|false|
|dest-image-tag|The tag of the destination image when the tar file is loaded. Use this if you want to hide the source repository name, or if you have issues with digest missmatch which can happen sometimes with `podman save` and `podman load`|""|false|
|output-artifact|The output url that points to the OCI artifact of the tar image||true|

## Results
|name|description|
|---|---|
|ARTIFACT_URL|Repository where the oci-archive tar artifact was pushed|
|ARTIFACT_DIGEST|Digest of the oci-archive tar artifact just pushed|
