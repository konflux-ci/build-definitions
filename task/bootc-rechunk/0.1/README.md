# Bootc-Rechunk task

## Overview

The `bootc-rechunk` task is a Tekton task used to chunk an OCI image into smaller chunks for more efficient management, with the goal of reducing image size. This task is designed to work in conjunction with other container build tasks (e.g., `buildah-oci-ta`). It takes an existing image, processes it, and outputs a chunked OCI archive.

## Inputs

- **IMAGE**: The reference of the image to be chunked (required). This image will be used as the input for the rechunking process.
  
## Outputs

- **OCI Archive**: A chunked OCI image that is output after the process completes. The output is saved to the specified path in the task parameters.

## Parameters

### Required Parameters
- `IMAGE`: Reference to the image that needs to be chunked (e.g., `$(params.output-image)`).

### Optional Parameters
- `OUTPUT_PATH`: The path where the chunked OCI archive will be saved. Defaults to `/buildcontext`.

## Task Execution Flow

1. **Input Image**: The task receives an image reference as input through the `IMAGE` parameter.
2. **Chunking**: The task uses the image as input and processes it to generate a chunked OCI archive.
3. **Output**: The output is saved to a path defined by `OUTPUT_PATH` (default is `/buildcontext`).

## Example Usage in Tekton Pipeline

```yaml
apiVersion: tekton.dev/v1beta1
kind: PipelineRun
metadata:
  name: pipeline-run-example
spec:
  pipelineRef:
    name: example-pipeline
  params:
    - name: output-image
      value: my-image:latest
  resources:
    - name: source-repo
      resourceRef:
        name: my-git-repo
