# Changelog

## 0.2

### Added

- Merge Syft-scanned base-image packages into the ModelCar composition SBOM
  (`mobster generate modelcar`) so release can populate the package database.

### Changed

- Temporarily pin task-runner 3.0.0 and drop olot `--root-dir` until
  [containers/olot#216](https://github.com/containers/olot/pull/216) lands.
  Nested model paths flatten to basenames meanwhile; restore `--root-dir` with
  task-runner >= 3.1.1 after the upstream fix.
