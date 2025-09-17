# sealights-python-oci-ta task

This Tekton task automates the process of configuring your Python application with Sealights for quality analytics and testing. It retrieves the source code from a trusted artifact, installs Python Sealights agent, configures the app for Sealights using vars from your PipelineRun, scans all .py files, reports scan to Sealights, and stores results to be used later on in testing. The task can be triggered by either Pull Request or other events.

## Parameters
|name|description|default value|required|
|---|---|---|---|
|SOURCE_ARTIFACT|The Trusted Artifact URI pointing to the artifact with the application source code.||true|
|component|The name of the Konflux component associated with the integration tests.||true|
|scm-provider|The source control management (SCM) provider used for the project, such as 'Github', 'Gitlab'.|github|false|
|exclude|A list of paths to exclude from Sealights instrumentation during the code scan. Specify paths to prevent them from being analyzed (e.g., '/app/source/tests/*','/app/examples/*').|[]|false|
|repository-url|The name or URL of the source code repository (e.g., 'github.com/org/repo').|""|false|
|branch|The name of the Git branch to use for the operation (e.g., 'main' or 'feature-branch').|main|false|
|revision|The Git revision (commit SHA) from which the test pipeline is originating.||true|
|pull-request-number|The identifier number of the pull request/merge request.|""|false|
|target-branch|The name of the target branch for the pull request, typically the branch into which the changes will be merged (e.g., 'main', 'develop').|main|false|
|workspace-path|The path to the root of your repository.||true|

## Results
|name|description|
|---|---|
|sealights-bsid|A unique identifier generated for the current Sealights build session.|
|sealights-build-name|A unique build name generated using the commit SHA and current date to prevent conflicts during test reruns.|
|sealights-agent-version|A version of the Sealights Python Agent|


## Additional info

## Overview

This task performs the following steps:

1. **Retrieves** the source code from a trusted artifact.
2. **Configures & Scans** the Python application using Sealights.

## Volumes

| Name                  | Description                                                    |
|-----------------------|----------------------------------------------------------------|
| `sealights-credentials` | Stores Sealights credentials from the specified secret.         |
| `workdir`             | Temporary working directory for source code operations.        |

## Steps

### 1. `use-trusted-artifact`

Retrieves the source code from a trusted artifact.

### 2. `sealights-python-instrumentation`

Configures and Scans the Python application using Sealights.

## Usage Instructions

### Create the Sealights Secret (REQUIRED)

Ensure you have a Kubernetes secret named **sealights-credentials** containing your Sealights agent token.

We assign the SEALIGHTS_TOKEN var in the script with this command.
```SEALIGHTS_TOKEN="$(cat /usr/local/sealights-credentials/token)"```
>NOTE: you must name the value of the secret **token**.

For example:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: sealights-credentials
type: Opaque
data:
  token: <BASE64_ENCODED_SEALIGHTS_TOKEN>
```
