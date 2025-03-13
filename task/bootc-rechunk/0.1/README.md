# bootc-rechunk Task

## Overview
The `bootc-rechunk` task is a Tekton task for running the `rpm-ostree experimental build-chunked-oci` command as a separate step in the pipeline. It generates a chunked OCI image from the root filesystem.

## Parameters
- **`IMAGE_TAG`** (string) - The tag for the OCI image.
- **`OUTPUT_PATH`** (string) - The directory to store the output OCI image (default: `/buildcontext`).

## Usage
Add this task to your Tekton pipeline to run the `bootc-rechunk` step before the final image build.

Example:
```yaml
- name: bootc-rechunk
  taskRef:
    name: bootc-rechunk
  params:
    - name: IMAGE_TAG
      value: "$(params.IMAGE_TAG)"
    - name: OUTPUT_PATH
      value: "/buildcontext"
