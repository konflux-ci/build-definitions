# sealights-go-oci-ta task

This Tekton task automates the process of instrumenting Go code with Sealights for quality analytics and testing. It retrieves the source code from a trusted artifact, instruments the code with Sealights, and then creates a new trusted artifact with the instrumented code. The task can be triggered by either Pull Request or other events.

## Parameters
|name|description|default value|required|
|---|---|---|---|
|SOURCE_ARTIFACT|The Trusted Artifact URI pointing to the artifact with the application source code.||true|
|component|The name of the Konflux component associated with the integration tests.||true|
|scm-provider|The source control management (SCM) provider used for the project, such as 'github', 'gitlab'.|github|false|
|packages-excluded|A list of Go packages to exclude from Sealights instrumentation during the code scan. Specify package paths to prevent them from being analyzed (e.g., 'pkg1', 'github.com/modern-go/concurrent').|[]|false|
|repository-url|The name or URL of the source code repository (e.g., 'github.com/org/repo').|""|false|
|branch|The name of the Git branch to use for the operation (e.g., 'main' or 'feature-branch').|main|false|
|revision|The Git revision (commit SHA) from which the test pipeline is originating.||true|
|pull-request-number|The identifier number of the pull request/merge request.|""|false|
|target-branch|The name of the target branch for the pull request, typically the branch into which the changes will be merged (e.g., 'main', 'develop').|main|false|
|oci-storage|The OCI repository where the Trusted Artifacts are stored.||true|
|debug|Enable debug for Sealights scanning.|false|false|
|disable-token-save|Skip saving the Sealights token to the trusted artifact and container image (it will require providing the token during deployment)|false|false|
|workspace-path|Contains the path to the code directory to scan|./|false|

## Results
|name|description|
|---|---|
|sealights-bsid|A unique identifier generated for the current sealights build session.|
|sealights-build-name|A unique build name generated using the commit SHA and current date to prevent conflicts during test reruns.|
|sealights-agent-version|A version of the Sealights Go Agent|
|sealights-cli-version|A version of the Sealights Go CLI|
|SOURCE_ARTIFACT|The Trusted Artifact URI pointing to the artifact with the application source code.|
|TEST_OUTPUT|Stores the sealights results in json format to warn users in case of any Sealights glitches.|


## Additional info

## Overview

This task performs the following steps:

1. **Retrieves** the source code from a trusted artifact.
2. **Instruments** the Go code using Sealights.
3. **Creates** a new trusted artifact containing the instrumented code.

## Volumes

| Name                  | Description                                                    |
|-----------------------|----------------------------------------------------------------|
| `sealights-credentials` | Stores Sealights credentials from the specified secret.         |
| `workdir`             | Temporary working directory for source code operations.        |

## Steps

### 1. `use-trusted-artifact`

Retrieves the source code from a trusted artifact.

### 2. `sealights-go-instrumentation`

Instruments the Go code with Sealights.

### 3. `create-trusted-artifact`

Creates a new trusted artifact containing the instrumented code and stores it in the specified OCI repository.

## Usage Instructions

### Create the Sealights Secret

Ensure you have a Kubernetes secret containing your Sealights credentials. For example:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: sealights-credentials
type: Opaque
data:
  token: <BASE64_ENCODED_SEALIGHTS_TOKEN>
```
