# Sealights Go Instrumentation Tekton Task

This Tekton task automates the process of instrumenting Go code with Sealights for quality analytics and testing. It retrieves source code from a trusted artifact, instruments it with Sealights, and creates a new trusted artifact with the instrumented code. This task supports Pull Request and Push events and provides flexibility to exclude specific Go packages from instrumentation.

## Overview

This task performs the following steps:

1. **Retrieves** the source code from a trusted artifact.
2. **Instruments** the Go code using Sealights.
3. **Creates** a new trusted artifact containing the instrumented code.

The task can be triggered by different events (e.g., Pull Request, Push) and allows users to exclude specific Go packages from the instrumentation process.

## Parameters

| Name                  | Type     | Default       | Description                                                                                   |
|-----------------------|----------|---------------|-----------------------------------------------------------------------------------------------|
| `SOURCE_ARTIFACT`     | `string` | -             | The Trusted Artifact URI pointing to the source code.                                         |
| `go-version`          | `string` | -             | The Go version to use (e.g., `1.21.3`).                                                       |
| `component`           | `string` | -             | The name of the Konflux component associated with the integration tests.                      |
| `scm-provider`        | `string` | `github`      | The SCM provider (e.g., `github`, `gitlab`).                                                  |
| `packages-excluded`   | `array`  | `[]`          | List of Go packages to exclude from instrumentation (e.g., `pkg1`, `github.com/lib/concurrent`). |
| `repository-url`      | `string` | `""`          | URL of the source code repository (e.g., `github.com/org/repo`).                              |
| `branch`              | `string` | `main`        | The Git branch to use (e.g., `main`, `feature-branch`).                                       |
| `revision`            | `string` | -             | The Git revision (commit SHA).                                                                |
| `pull-request-number` | `string` | `""`          | The Pull Request number.                                                                      |
| `target-branch`       | `string` | `main`        | The target branch for the Pull Request (e.g., `main`, `develop`).                             |
| `oci-storage`         | `string` | -             | The OCI repository for storing the trusted artifacts.                                         |

## Results

| Name                | Type     | Description                                                                 |
|---------------------|----------|-----------------------------------------------------------------------------|
| `build-session-id`  | `string` | A unique identifier for the Sealights build session.                       |
| `build-name`        | `string` | A unique build name generated using the commit SHA and current date.       |
| `SOURCE_ARTIFACT`   | `string` | The URI of the trusted artifact with the application source code.          |

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
