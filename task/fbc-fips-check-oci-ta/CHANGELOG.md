# Changelog

## Unreleased

<!--
When you make changes without bumping the version right away, document them here.
If that's not something you ever plan to do, consider removing this section.
-->

*Nothing yet.*

## 0.2

### Added

- Matrix mode for parallel FIPS checking with `fbc-fips-prepare-oci-ta`
- New parameters: `BUCKETS_ARTIFACT`, `BUCKET_INDEX`
- Migration script `migrations/0.2.sh` for automated pipeline updates

### Changed

- Task now requires pairing with `fbc-fips-prepare-oci-ta` for image extraction
- Parameters changed from v0.1 (not backward compatible)

### Note

v0.1 and v0.2 serve different use cases:
- **v0.1**: Standalone mode - single task, simple setup
- **v0.2**: Matrix mode - parallel processing with `fbc-fips-prepare-oci-ta`

Choose the version that fits your needs. See MIGRATION.md for guidance.

## 0.1

### Added

- The initial version of the `fbc-fips-check-oci-ta` task!
