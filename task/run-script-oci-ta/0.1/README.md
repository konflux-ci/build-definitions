# run-script-oci-ta task

## Description:

The run-script-oci-ta task allows to run an script stored on the git repository or the script execution container image as part of the build pipeline.

The task allows to transform the git repository content before building. This is useful when you need to generate the `Containerfile` on the fly or modify the build context directory.

## Params:

| name                          | description                                                                                                                 | default value       |required |
|-------------------------------|-----------------------------------------------------------------------------------------------------------------------------|---------------------|---------|
| enableSymlinkCheck            | Check symlinks in the repo. If they're pointing outside of the repo, the build will fail.                                   |true                 | false   |
| ociArtifactExpiresAfter       | Expiration date for the trusted artifacts created in the OCI repository. An empty string means the artifacts do not expire. | ""                  | false   |
| ociStorage                    | The OCI repository where the Trusted Artifacts are stored.                                                                  |                     | true    |
| PREFETCH_ARTIFACT               | The Trusted Artifact URI pointing to the artifact with the prefetched dependencies.                                         | ""                  | false   |
| SCRIPT_RUNNER_IMAGE           | The image to run the script in                                                                                              |                     | true    |
| SCRIPT                        | The script to launch                                                                                                        |                     | true    |
| SCRIPT_WORKDIR                | The directory to launch the script from                                                                                     | .                   | false   |
| SCRIPT_ARTIFACT_RELATIVE_PATH | The relative path relative to the source directory to store on the SCRIPT_ARTIFACT                                          | /var/workdir/source | false   |
| STORAGE_DRIVER                | Storage driver to configure for buildah                                                                                     | vfs                 | false   |
| HERMETIC                      | Determines if build will be executed without network access.                                                                | false               | false   |
| caTrustConfigMapName          | The name of the key in the ConfigMap that contains the CA bundle data.                                                      | ca-bundle.crt       | false   |

## Results:

| name                          | description                                                                                     |
|-------------------------------|-------------------------------------------------------------------------------------------------|
| SCRIPT_ARTIFACT               | The Trusted Artifact URI pointing to the artifact with the content of SCRIPT_ARTIFACT_DIRECTORY |
| SCRIPT_RUNNER_IMAGE_REFERENCE | Image reference and digest of the image used to run the script                                  |
| SCRIPT_OUTPUT                 | String output of the script. Content of /var/workdir/output/output file populated by the script |
| SCRIPT_OUTPUT_ARRAY           | Array output of the script. Content of /var/workdir/output/array file populated by the script   |

## Specifycing the script

`SCRIPT` parameter can be:

- A command line using a tool on `SCRIPT_RUNNER_IMAGE` `$PATH` directories:

```yaml
- name: SCRIPT
  value: ls /var/workdir/source
```

- A relative path command stored on the git repository relative to `SCRIPT_WORKDIR`:

```yaml
- name: SCRIPT
  value: ./my-script.sh --foo --bar
```

- An inline sh script:

```yaml
- name: SCRIPT
  value: |
    echo "Hello world"
```

## Populating results

There are two environment variables  on the script execution environment available for the script to optionally populate `SCRIPT_OUTPUT` and `SCRIPT_OUTPUT_ARRAY` results.

It is up to the user defined script to populate those.

```sh
#!/bin/bash

echo -n "my string result" > "${SCRIPT_OUTPUT}"
echo -n '["my", "array", "result"]' > "${SCRIPT_OUTPUT_ARRAY}"
```
