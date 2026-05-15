# Changelog

## Unreleased

### Fixed

- Updated the `fips-operator-check-step-action` revision parameter to use `check-payload` release `0.3.14`.

## 0.1

### Added

- Initial version of `fips-operator-bundle-check` task
- Single operator bundle FIPS checking with `check-payload`
- Scans relatedImages from the operator bundle image
- Expects an image digest mirror set at `.tekton/images-mirror-set.yaml` when mirroring is required

### Note

Workspace-source variant; the Trusted Artifacts equivalent is `fips-operator-bundle-check-oci-ta`.
