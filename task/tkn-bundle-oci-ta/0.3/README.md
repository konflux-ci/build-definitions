# tkn-bundle-oci-ta task

Creates and pushes a Tekton bundle containing the specified Tekton YAML files.

## Parameters
|name|description|default value|required|
|---|---|---|---|
|CONTEXT|Path to the directory to use as context.|.|false|
|HOME|Value for the HOME environment variable.|/tekton/home|false|
|IMAGE|Reference of the image task will produce.||true|
|REVISION|Revision||true|
|SOURCE_ARTIFACT|The Trusted Artifact URI pointing to the artifact with the application source code.||true|
|STEPS_IMAGE|An optional image to configure task steps with in the bundle|""|false|
|STEPS_IMAGE_STEP_NAMES|Optional comma- or space-separated step names to control which steps are updated with STEPS_IMAGE. If names are prefixed with ! then all steps except those are updated. Otherwise only the listed steps are updated. If empty, all step images are updated.|""|false|
|URL|Source code Git URL||true|

## Results
|name|description|
|---|---|
|IMAGE_DIGEST|Digest of the image just built|
|IMAGE_REF|Image reference of the built image|
|IMAGE_URL|Image repository and tag where the built image was pushed with tag only|


## Additional info
