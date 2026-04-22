# Changelog

## Unreleased

<!--
When you make changes without bumping the version right away, document them here.
If that's not something you ever plan to do, consider removing this section.
-->

*Nothing yet.*

## 0.1

### Added

- Initial version of `fbc-fips-check-matrix-based-oci-ta` task
- Matrix-based parallel FIPS checking with Tekton matrix expansion
- Parameters: `BUCKETS_ARTIFACT`, `BUCKET_INDEX`, `MAX_PARALLEL`
- Error propagation from `fbc-fips-prepare-oci-ta` via bucket artifacts

### Note

This is the matrix version of `fbc-fips-check-oci-ta`. Both tasks have the same FIPS compliance checking functionality:
- `fbc-fips-check-oci-ta` - Standalone mode, single task
- `fbc-fips-check-matrix-based-oci-ta` - Matrix mode, parallel processing with `fbc-fips-prepare-oci-ta`
