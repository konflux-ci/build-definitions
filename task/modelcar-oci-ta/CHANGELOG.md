# Changelog

## 0.1.1

### Fixed

- Replaced expired `release-service-utils` image reference with a digest-pinned
  reference. The previous tag (`2f93b7ed`) was deleted from Quay.io, breaking
  the `create-modelcar-base-image` step.

### Added

- Started tracking changes in this file.