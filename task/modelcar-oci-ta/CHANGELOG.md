# Changelog

## 0.2

### Added

- Merge Syft-scanned base-image packages into the ModelCar composition SBOM
  (`mobster generate modelcar`) so release can populate the package database.
- Convert Docker-distribution manifests in the base OCI layout once before the
  multi-batch olot loop (workaround for
  [containers/olot#216](https://github.com/containers/olot/pull/216)).

### Changed

- Temporarily pin task-runner 3.0.0 and drop olot `--root-dir` until
  [containers/olot#216](https://github.com/containers/olot/pull/216) lands.
  Nested model paths flatten to basenames meanwhile; restore `--root-dir` with
  task-runner >= 3.1.1 after the upstream fix.
