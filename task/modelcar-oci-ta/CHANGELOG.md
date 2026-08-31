# Changelog

## 0.1

### Added

- Rely on Mobster's built-in base-image Syft scan when generating the ModelCar
  SBOM (`mobster generate modelcar`), so packages land under the base image
  node (SPDX and CycloneDX) and release can populate the package database.

### Changed

- Bump task-runner to 3.1.2 (`olot` 1.2.1), which includes the multi-batch
  Docker→OCI conversion fix from
  [containers/olot#216](https://github.com/containers/olot/pull/216). Keep
  `--root-dir models` so nested model paths are preserved, and drop the
  in-task Docker→OCI pre-batch conversion workaround.
