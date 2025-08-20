# source-build task

Source image build.

## Parameters
|name|description|default value|required|
|---|---|---|---|
|BINARY_IMAGE|Binary image name from which to generate the source image name.||true|
|BASE_IMAGES|By default, the task inspects the SBOM of the binary image to find the base image. With this parameter, you can override that behavior and pass the base image directly. The value should be a newline-separated list of images, in the same order as the FROM instructions specified in a multistage Dockerfile.|""|false|
|IGNORE_UNSIGNED_IMAGE|When set to "true", source build task won't fail when source image is missing signatures (this can be used for development)|false|false|

## Results
|name|description|
|---|---|
|BUILD_RESULT|Build result.|
|SOURCE_IMAGE_URL|The source image url.|
|SOURCE_IMAGE_DIGEST|The source image digest.|
|IMAGE_REF|Image reference of the built image.|

## Workspaces
|name|description|optional|
|---|---|---|
|workspace|The workspace where source code is included.|false|

## Additional info
