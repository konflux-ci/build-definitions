# Changelog

## Unreleased

### Fixed

- Replace the ad-hoc 4-line minor-version arithmetic with a call to the shared `get_prev_ocp_version()` helper now available in `utils.sh` (`konflux-test:v1.5.0`). The helper correctly handles the v5.0 → v4.22 cross-major boundary.

## 0.1

### Added

- Initial version of `fbc-fips-check-oci-ta` task
- Trusted Artifacts (`SOURCE_ARTIFACT`) variant of FBC fragment FIPS checking with `check-payload`
- Scans relatedImages from unreleased operator bundles in an FBC fragment image
- Parameters include `MAX_PARALLEL` and `image-mirror-set-path` for mirror resolution

### Note

This is the Trusted Artifacts variant of `fbc-fips-check` (`fbc-fips-check` uses a workspace source instead of `SOURCE_ARTIFACT`).
