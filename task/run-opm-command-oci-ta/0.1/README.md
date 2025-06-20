# run-opm-command-oci-ta task

This Task allows you to execute `opm` (Operator Package Manager) commands 
within a Tekton Pipeline. It's designed to work with **Trusted Artifacts** 
and helps in automating the process of generating and validating OPM-related outputs, such as file-based catalogs.

---

## Table of Contents

* [Overview](#overview)
* [Parameters](#parameters)
* [Results](#results)

---

## Overview

The `run-opm-command-oci-ta` Task performs the following key steps:

1.  **Retrieves Source Artifacts**: Downloads your application's source code, which should contain any necessary `opm` inputs (e.g., catalog templates).
2.  **Executes OPM Command**: Runs the `opm` command with user-defined arguments and redirects the output to a specified file within the source directory. This step is configured to fail if the output path is not provided or is absolute.
3.  **Applies ImageDigestMirrorSet (Optional)**: If an `ImageDigestMirrorSet` (IDMS) file is provided, this step replaces image pull specifications in the generated OPM output (e.g., in a catalog) based on the mirror definitions in the IDMS file. This is crucial for environments where images need to be pulled from internal registries.
4.  **Validates Catalog**: Runs `opm validate` on the generated output to ensure its correctness.
5.  **Creates Trusted Artifact**: Uploads the modified source directory (including the `opm` command's output) as a new Trusted Artifact.

---

## Parameters

| Parameter           | Description                                                                                                                                                       | Type    | Required | Default               |
| :------------------ |:------------------------------------------------------------------------------------------------------------------------------------------------------------------| :------ | :------- | :-------------------- |
| `SOURCE_ARTIFACT`   | The Trusted Artifact URI pointing to the artifact with the application source code.                                                                               | `string`| Yes      |                       |
| `ociStorage`        | The OCI repository where the Trusted Artifacts are stored.                                                                                                        | `string`| Yes      |                       |
| `OPM_ARGS`          | An array of arguments to pass directly to the `opm` command (e.g., `['alpha', 'render-template', 'basic', 'v4.18/catalog-template.json']`).                       | `array` | Yes      |                       |
| `OPM_OUTPUT_PATH`   | The relative path for the `opm` command's output file (e.g., `'v4.18/catalog/example-operator/catalog.json'`). Relative to the root directory of the source code. | `string`| Yes      |                       |
| `IDMS_PATH`         | Path to an `ImageDigestMirrorSet` file (e.g., `.tekton/images-mirror-set.yaml`). Used to replace related image pullspecs in the catalog.                          | `string`| No       | `""` (empty string) |

---

## Results

| Result            | Description                                                                                                 |
| :---------------- | :---------------------------------------------------------------------------------------------------------- |
| `SOURCE_ARTIFACT` | The Trusted Artifact URI pointing to the artifact with the application source code, now including the generated file-based catalog. |

