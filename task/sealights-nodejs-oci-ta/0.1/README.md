# Sealights Node.js Instrumentation Tekton Task

This Tekton task automates the process of instrumenting Node.js code with Sealights for quality analytics and testing. It retrieves the source code from a trusted artifact, installs Node.js Sealights agent, configures the app for Sealights using vars from your PipelineRun, scans all .js files, reports scan to Sealights (in case of `backend` type of application), and stores results to be used later on in testing. The task can be triggered by either Pull Request or other events.

## Overview

This task performs the following steps:

1. **Retrieves** the source code from a trusted artifact.
2. **Configures** the Node.js application using Sealights.
3. **Scans** the Node.js application (`frontend` applications need be scanned during application deployment).

The task can be triggered by different events (e.g., Pull Request, Push) and allows users to exclude specific paths from the configuration process.

## Parameters

| Name                  | Type     | Default       | Description                                                                                   |
|-----------------------|----------|---------------|-----------------------------------------------------------------------------------------------|
| `SOURCE_ARTIFACT`     | `string` | -             | The Trusted Artifact URI pointing to the source code.                                         |
| `component`           | `string` | -             | The name of the Konflux component associated with the integration tests.                      |
| `is-frontend`           | `string` | "false"             | In case of frontend application the scanning part is skipped (it needs to be performed during deployment)                      |
| `scm-provider`        | `string` | `Github`         | The SCM provider (e.g., `Github`).                                                               |
| `exclude`   | `array`  | `[]`          | A list of paths to exclude from Sealights instrumentation during the code scan. Specify paths to prevent them from being analyzed (e.g., 'tests/*','examples/*'). |
| `repository-url`      | `string` | `""`          | URL of the source code repository (e.g., `github.com/org/repo`).                              |
| `branch`              | `string` | `main`        | The Git branch to use (e.g., `main`, `feature-branch`).                                       |
| `revision`            | `string` | -             | The Git revision (commit SHA).                                                                |
| `pull-request-number` | `string` | `""`          | The Pull Request number.                                                                      |
| `target-branch`       | `string` | `main`        | The target branch for the Pull Request (e.g., `main`, `develop`).                             |
| `workspace-path`       | `string` | `.`        | Path to the directory that should be scanned (valid for non-frontend Node.js applications).                             |

## Results

| Name                | Type     | Description                                                                 |
|---------------------|----------|-----------------------------------------------------------------------------|
| `sealights-bsid`    | `string` | A unique identifier for the Sealights build session.                       |
| `sealights-build-name`        | `string` | A unique build name generated using the commit SHA and current date.       |

## Volumes

| Name                  | Description                                                    |
|-----------------------|----------------------------------------------------------------|
| `sealights-credentials` | Stores Sealights credentials from the specified secret.         |
| `workdir`             | Temporary working directory for source code operations.        |

## Steps

### 1. `use-trusted-artifact`

Retrieves the source code from a trusted artifact.

### 2. `sealights-nodejs-instrumentation`

Configures Node.js application using Sealights. If the application is not a frontend type, it's also scanned.

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