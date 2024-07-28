# oci-copy-oci-ta task

Given a file in the user's source directory, copy content from arbitrary urls into the OCI registry.

## Parameters
|name|description|default value|required|
|---|---|---|---|
|AWS_SECRET_NAME|Name of a secret which will be made available to the build to construct Authorization headers for requests to Amazon S3. If specified, this will take precedence over BEARER_TOKEN_SECRET_NAME.|does-not-exist|false|
|BEARER_TOKEN_SECRET_NAME|Name of a secret which will be made available to the build as an Authorization header. Note, the token will be sent to all servers found in the oci-copy.yaml file. If you do not wish to send the token to all servers, different taskruns and therefore different oci artifacts must be used.|does-not-exist|false|
|IMAGE|Reference of the image we will push||true|
|OCI_COPY_FILE|Path to the oci copy file.|./oci-copy.yaml|false|
|SOURCE_ARTIFACT|The Trusted Artifact URI pointing to the artifact with the application source code.||true|

## Results
|name|description|
|---|---|
|IMAGE_DIGEST|Digest of the artifact just pushed|
|IMAGE_REF|Image reference of the built image|
|IMAGE_URL|Repository where the artifact was pushed|
|SBOM_BLOB_URL|Link to the SBOM blob pushed to the registry.|

