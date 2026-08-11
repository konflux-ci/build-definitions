# Changelog

## 0.2

### Added

- Merge Syft-scanned base-image packages into the ModelCar composition SBOM
  (`mobster generate modelcar`) so release can populate the package database.
- Convert Docker-distribution manifests in the base OCI layout once before the
  multi-batch olot loop (workaround for
  [containers/olot#216](https://github.com/containers/olot/pull/216)).

### Changed

- Keep task-runner 3.1.1 with olot `--root-dir models` so nested model paths are
  preserved. The Docker→OCI pre-batch convert replaces the temporary 3.0.0 /
  no-`--root-dir` pin.
