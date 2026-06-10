# Changelog

## Unreleased

### Fixed

- Updated the `fips-operator-check-step-action` revision parameter to use `check-payload` release `0.3.15`.
- Updated the `fips-operator-check-step-action` revision parameter to use `check-payload` release `0.3.14`.

## 0.1

### Added

- Initial version of `fips-operator-bundle-check-oci-ta` task
- Trusted Artifacts (`SOURCE_ARTIFACT`) variant of single operator bundle FIPS checking with `check-payload`
- Scans relatedImages from the operator bundle image
- Expects an image digest mirror set at `.tekton/images-mirror-set.yaml` when mirroring is required

### Note

This is the Trusted Artifacts variant of `fips-operator-bundle-check`.
