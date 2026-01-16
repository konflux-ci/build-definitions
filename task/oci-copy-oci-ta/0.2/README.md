# oci-copy-oci-ta task

Given a file in the user's source directory, copy content from arbitrary urls into the OCI registry.

## Parameters
|name|description|default value|required|
|---|---|---|---|
|AWS_SECRET_NAME|Name of a secret which will be made available to the build for downloading from Amazon S3 or S3-compatible storage using AWS CLI with parallel multipart transfers. If specified, this will take precedence over BEARER_TOKEN_SECRET_NAME. The secret must contain two keys: `aws_access_key_id` and `aws_secret_access_key`.|does-not-exist|false|
|BEARER_TOKEN_SECRET_NAME|Name of a secret which will be made available to the build as an Authorization header. Note, the token will be sent to all servers found in the oci-copy.yaml file. If you do not wish to send the token to all servers, different taskruns and therefore different oci artifacts must be used.|does-not-exist|false|
|IMAGE|Reference of the image we will push||true|
|OCI_COPY_FILE|Path to the oci copy file.|./oci-copy.yaml|false|
|SBOM_TYPE|Select the SBOM format to generate. Valid values: spdx, cyclonedx.|spdx|false|
|SOURCE_ARTIFACT|The Trusted Artifact URI pointing to the artifact with the application source code.||true|

## Results
|name|description|
|---|---|
|IMAGE_DIGEST|Digest of the artifact just pushed|
|IMAGE_REF|Image reference of the built image|
|IMAGE_URL|Repository where the artifact was pushed|
|SBOM_BLOB_URL|Link to the SBOM blob pushed to the registry.|


## Additional info
