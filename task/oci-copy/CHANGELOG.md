# Changelog

## 0.2.2

### Fixed

- Remove `extra_headers` from the OCI copy file before SBOM generation because Mobster does not support the field.

## 0.2.1

### Added

- Support optional per-artifact `extra_headers` in `oci-copy.yaml` for curl downloads.
