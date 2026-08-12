# Changelog

## 0.1

### Added

- Rely on Mobster's built-in base-image Syft scan when generating the ModelCar
  SBOM (`mobster generate modelcar`), so packages land under the base image
  node (SPDX and CycloneDX) and release can populate the package database.

### Changed

- Temporarily pin task-runner 3.0.0 and drop olot `--root-dir` until
  [containers/olot#216](https://github.com/containers/olot/pull/216) lands.
  Nested model paths flatten to basenames meanwhile; restore `--root-dir` with
  task-runner >= 3.1.1 after the upstream fix.
