# oci-copy-large task

Given a file in the user's source directory, copy content from arbitrary urls into the OCI registry.

## Parameters
|name|description|default value|required|
|---|---|---|---|
|IMAGE|Reference of the image we will push||true|
|OCI_COPY_FILE|Path to the oci copy file.|./oci-copy-large.yaml|false|
|BEARER_TOKEN_SECRET_NAME|Name of a secret which will be made available to the build as an Authorization header. Note, the token will be sent to all servers found in the oci-copy-large.yaml file. If you do not wish to send the token to all servers, different taskruns and therefore different oci artifacts must be used.|does-not-exist|false|
|AWS_SECRET_NAME|Name of a secret which will be made available to the build to construct Authorization headers for requests to Amazon S3 using v2 auth https://docs.aws.amazon.com/AmazonS3/latest/userguide/RESTAuthentication.html. If specified, this will take precedence over BEARER_TOKEN_SECRET_NAME. The secret must contain two keys: `aws_access_key_id` and `aws_secret_access_key`. In the future, this will be reimplemented to use v4 auth: https://docs.aws.amazon.com/AmazonS3/latest/API/sigv4-auth-using-authorization-header.html.|does-not-exist|false|
|SBOM_TYPE|Select the SBOM format to generate. Valid values: spdx, cyclonedx.|spdx|false|

## Results
|name|description|
|---|---|
|IMAGE_DIGEST|Digest of the artifact just pushed|
|IMAGE_URL|Repository where the artifact was pushed|
|SBOM_BLOB_URL|Link to the SBOM blob pushed to the registry.|
|IMAGE_REF|Image reference of the built image|

## Workspaces
|name|description|optional|
|---|---|---|
|source|Workspace containing the source artifacts to copy|false|

## Additional info

### When to use this task

Use `oci-copy-large` instead of the standard `oci-copy` task when:
- Downloading large files (multi-gigabyte) from S3-compatible storage
- You need faster transfer speeds via parallel multipart downloads
- Working with AI/ML model files or other large artifacts

### Key differences from oci-copy

| Feature | oci-copy | oci-copy-large |
|---------|----------|----------------|
| Download method | curl | AWS CLI with parallel multipart |
| CPU request | default | 2 cores |
| Memory | default | 2-4Gi |
| S3 optimization | None | 50 concurrent requests, 64MB multipart threshold, 16MB chunks |

### AWS S3 parallel downloads

When AWS credentials are provided via `AWS_SECRET_NAME`, this task uses the AWS CLI with optimized settings for large file transfers:
- **50 concurrent requests** for parallel downloads
- **64MB multipart threshold** - files larger than this use multipart
- **16MB chunk size** for multipart transfers

### Supported S3 URL formats

The task automatically detects and handles the following URL formats:

| Provider | Style | Example URL |
|----------|-------|-------------|
| AWS | Virtual-hosted | `https://bucket.s3.us-east-1.amazonaws.com/path/to/file` |
| AWS | Path-style | `https://s3.us-east-1.amazonaws.com/bucket/path/to/file` |
| IBM Cloud COS | Virtual-hosted | `https://bucket.s3.us-south.cloud-object-storage.appdomain.cloud/path/to/file` |
| IBM Cloud COS | Path-style | `https://s3.us-south.cloud-object-storage.appdomain.cloud/bucket/path/to/file` |
| Generic S3 | Path-style | `https://s3.example.com/bucket/path/to/file` |

## oci-copy-large.yaml schema
JSON schema for the `oci-copy-large.yaml` file.

```json
{
    "type": "object",
    "required": ["artifacts", "artifact_type"],
    "properties": {
        "artifact_type": {
            "description": "Artifact type to be applied to the top-level OCI artifact, i.e. `application/x-mlmodel`",
            "type": "string"
        },
        "artifacts": {
            "type": "array",
            "items": {
                "type": "object",
                "required": ["source", "filename", "type", "sha256sum"],
                "properties": {
                    "source": {
                        "description": "URL of the artifact to copy",
                        "type": "string"
                    },
                    "filename": {
                        "description": "Filename that should be applied to the artifact in the OCI registry",
                        "type": "string"
                    },
                    "type": {
                        "description": "Media type that should be applied to the artifact in the OCI registry",
                        "type": "string"
                    },
                    "sha256sum": {
                        "description": "Digest of the artifact to be checked before copy",
                        "type": "string"
                    }
                }
            }
        }
    }
}
```
