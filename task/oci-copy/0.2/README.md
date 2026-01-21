# oci-copy task

Copy content from arbitrary urls into the OCI registry. Downloads and pushes files in parallel for faster throughput.

## Parameters
|name|description|default value|required|
|---|---|---|---|
|IMAGE|Reference of the image we will push||true|
|OCI_COPY_FILE|Path to the oci copy file.|./oci-copy.yaml|false|
|BEARER_TOKEN_SECRET_NAME|Name of a secret which will be made available to the build as an Authorization header. Note, the token will be sent to all servers found in the oci-copy.yaml file. If you do not wish to send the token to all servers, different taskruns and therefore different oci artifacts must be used.|does-not-exist|false|
|AWS_SECRET_NAME|Name of a secret for downloading from Amazon S3 or S3-compatible storage using AWS CLI with parallel multipart transfers. Takes precedence over BEARER_TOKEN_SECRET_NAME. Required keys: `aws_access_key_id` and `aws_secret_access_key`.|does-not-exist|false|
|SBOM_TYPE|Select the SBOM format to generate. Valid values: spdx, cyclonedx.|spdx|false|
|PARALLEL_JOBS|Number of files to download/push in parallel. Requires disk space for concurrent downloads (e.g., 8 files x 10GB = 80GB).|8|false|

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

### AWS S3 downloads

When AWS credentials are provided via `AWS_SECRET_NAME`, this task uses the AWS CLI with optimized settings for parallel multipart file transfers.

S3 transfer settings are optimized for parallel multipart downloads:
- **max_concurrent_requests**: 50
- **multipart_threshold**: 64MB
- **multipart_chunksize**: 16MB

For large artifacts (multi-GB), you may want to adjust parallelism based on available disk space:

```yaml
params:
  - name: PARALLEL_JOBS
    value: "8"   # Reduce if disk space is limited (8 x max_file_size)
```

**Disk space requirement**: `PARALLEL_JOBS × max_file_size`. Default of 8 with 10GB files needs ~80GB.

### Supported S3 URL formats

| Provider | Style | Example URL |
|----------|-------|-------------|
| AWS | Virtual-hosted | `https://bucket.s3.us-east-1.amazonaws.com/path/to/file` |
| AWS | Path-style | `https://s3.us-east-1.amazonaws.com/bucket/path/to/file` |
| IBM Cloud COS | Virtual-hosted | `https://bucket.s3.us-south.cloud-object-storage.appdomain.cloud/path/to/file` |
| IBM Cloud COS | Path-style | `https://s3.us-south.cloud-object-storage.appdomain.cloud/bucket/path/to/file` |
| Generic S3 | Path-style | `https://s3.example.com/bucket/path/to/file` |

## oci-copy.yaml schema
JSON schema for the `oci-copy.yaml` file.

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
