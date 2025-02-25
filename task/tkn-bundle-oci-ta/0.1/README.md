# tkn-bundle-oci-ta task

Creates and pushes a Tekton bundle containing the specified Tekton YAML files.

## Parameters
|name|description|default value|required|
|---|---|---|---|
|CONTEXT|Path to the directory to use as context.|.|false|
|HOME|Value for the HOME environment variable.|/tekton/home|false|
|IMAGE|Reference of the image task will produce.||true|
|SOURCE_ARTIFACT|The Trusted Artifact URI pointing to the artifact with the application source code.||true|
|SOURCE_CODE_DIR|Source code directory in the working dir|source|false|
|STEPS_IMAGE|An optional image to configure task steps with in the bundle|""|false|

## Results
|name|description|
|---|---|
|IMAGE_DIGEST|Digest of the image just built|
|IMAGE_REF|Image reference of the built image|
|IMAGE_URL|Image repository and tag where the built image was pushed with tag only|

