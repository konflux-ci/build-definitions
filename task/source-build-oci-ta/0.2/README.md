# source-build-oci-ta task

Source image build.

## Parameters
|name|description|default value|required|
|---|---|---|---|
|BASE_IMAGES|By default, the task inspects the SBOM of the binary image to find the base image. With this parameter, you can override that behavior and pass the base image directly. The value should be a newline-separated list of images, in the same order as the FROM instructions specified in a multistage Dockerfile.|""|false|
|BINARY_IMAGE|Binary image name from which to generate the source image name.||true|
|CACHI2_ARTIFACT|The Trusted Artifact URI pointing to the artifact with the prefetched dependencies.|""|false|
|SOURCE_ARTIFACT|The Trusted Artifact URI pointing to the artifact with the application source code.||true|

## Results
|name|description|
|---|---|
|BUILD_RESULT|Build result.|
|IMAGE_REF|Image reference of the built image|
|SOURCE_IMAGE_DIGEST|The source image digest.|
|SOURCE_IMAGE_URL|The source image url.|

