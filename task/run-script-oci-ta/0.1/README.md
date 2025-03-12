# run-script-oci-ta task

## Description:

The run-script-oci-ta task allows to run an script stored on the git repository or the script execution container image as part of the build pipeline.

The two main use cases for this script are:

- Transform the git repository content before build. This is useful when you need to generate the `Containerfile` on the fly or modify the build context directory.
- Generate labels/annotations with custom code. This is useful when `generate-labels` task can not generate the type of labels/annotations you would like to include on the build.

## Params:

| name                      | description                                                                                                                 | default value       |required |
|---------------------------|-----------------------------------------------------------------------------------------------------------------------------|---------------------|---------|
| enableSymlinkCheck        | Check symlinks in the repo. If they're pointing outside of the repo, the build will fail.                                   |true                 | false   |
| ociArtifactsExpireAfter   | Expiration date for the trusted artifacts created in the OCI repository. An empty string means the artifacts do not expire. | ""                  | false   |
| ociStorage                | The OCI repository where the Trusted Artifacts are stored.                                                                  |                     | true    |
| SCRIPT_IMAGE              | The image to run the script in                                                                                              |                     | true    |
| SCRIPT                    | The script to launch                                                                                                        |                     | true    |
| SCRIPT_WORKDIR            | The directory to launch the script from                                                                                     | /var/workdir/script | false   |
| SCRIPT_ARTIFACT_DIRECTORY | The directory to include on the output Trusted Artifact                                                                     | /var/workdir/script | false   |
| STORAGE_DRIVER            | Storage driver to configure for buildah                                                                                     | vfs                 | false   |
| HERMETIC                  | Determines if build will be executed without network access.                                                                | false               | false   |
| caTrustConfigMapName      | The name of the key in the ConfigMap that contains the CA bundle data.                                                      | ca-bundle.crt       | false   |

## Results:

| name                | description                                                                                     |
|---------------------|-------------------------------------------------------------------------------------------------|
| SCRIPT_ARTIFACT     | The Trusted Artifact URI pointing to the artifact with the content of SCRIPT_ARTIFACT_DIRECTORY |
| SCRIPT_BASE_IMAGE   | Image reference and digest of the image used to run the script                                  |
| SCRIPT_OUTPUT       | String output of the script. Content of /var/workdir/output/output file populated by the script |
| SCRIPT_OUTPUT_ARRAY | Array output of the script. Content of /var/workdir/output/array file populated by the script   |

## Populating results

There are two predefined locations on the script execution environment available for the script to optionally populate `SCRIPT_OUTPUT` and `SCRIPT_OUTPUT_ARRAY` results.

It is up to the user defined script to populate those.

```sh
#!/bin/bash

echo -n "my string result" > /var/workdir/output/output
echo -n '["my", "array", "result"]' > /var/workdir/output/array
```
