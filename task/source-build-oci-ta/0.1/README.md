# source-build-oci-ta task

Source image build.

## Parameters
|name|description|default value|required|
|---|---|---|---|
|BASE_IMAGES|Base images used to build the binary image. Each image per line in the same order of FROM instructions specified in a multistage Dockerfile. Default to an empty string, which means to skip handling a base image.|""|false|
|BINARY_IMAGE|Binary image name from which to generate the source image name.||true|
|CACHI2_ARTIFACT|The Trusted Artifact URI pointing to the artifact with the prefetched dependencies.|""|false|
|SOURCE_ARTIFACT|The Trusted Artifact URI pointing to the artifact with the application source code.||true|

## Results
|name|description|
|---|---|
|BUILD_RESULT|Build result.|
|SOURCE_IMAGE_DIGEST|The source image digest.|
|SOURCE_IMAGE_URL|The source image url.|

