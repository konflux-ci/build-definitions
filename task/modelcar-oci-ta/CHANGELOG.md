# Changelog

## 0.1

### Added

- Rely on Mobster's built-in base-image Syft scan when generating the ModelCar
  SBOM (`mobster generate modelcar`), so packages land under the base image
  node (SPDX and CycloneDX) and release can populate the package database.

### Changed

- Keep task-runner 3.1.1 with olot `--root-dir models` so nested model paths are
  preserved. Pre-convert Docker-distribution manifests in the base OCI layout
  (and remove leftover Docker manifest blobs) before multi-batch `olot` runs,
  working around [containers/olot#216](https://github.com/containers/olot/pull/216)
  until that fix ships in task-runner (olot >= 1.2.1).
