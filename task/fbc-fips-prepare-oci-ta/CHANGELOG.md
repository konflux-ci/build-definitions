# Changelog

## Unreleased

<!--
When you make changes without bumping the version right away, document them here.
If that's not something you ever plan to do, consider removing this section.
-->

*Nothing yet.*

## 0.1

### Added

- Initial version of `fbc-fips-prepare-oci-ta` task
- Extracts unique relatedImages from unreleased FBC operator bundles
- Size-based load balancing across configurable number of buckets
- Parallel image size fetching with mirror support
- Creates OCI artifact with bucket files for matrix expansion
- Error propagation via `test_output.txt` in bucket artifact

### Note

This task is designed to work with `fbc-fips-check-matrix-based-oci-ta` for parallel FIPS checking.
