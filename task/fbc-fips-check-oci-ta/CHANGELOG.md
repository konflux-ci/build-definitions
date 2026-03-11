# Changelog

<!-- Format guidelines: https://keepachangelog.com/en/1.1.0/#how -->

## Unreleased

<!--
When you make changes without bumping the version right away, document them here.
If that's not something you ever plan to do, consider removing this section.
-->

*Nothing yet.*

## 0.2

### Added

- Dual-mode support via `NUM_WORKERS` parameter:
  - `NUM_WORKERS=1` (default): Inline mode - runs FIPS check directly, backward compatible with 0.1
  - `NUM_WORKERS>1`: Matrix mode - splits images into buckets for parallel processing with `fbc-fips-check-worker-oci-ta` tasks
- New parameters for matrix mode: `NUM_WORKERS`, `SIZE_FETCH_PARALLEL`, `ociStorage`, `ociArtifactExpiresAfter`
- New results for matrix mode: `BUCKETS_ARTIFACT`, `BUCKET_INDICES`, `TOTAL_IMAGES`
- Load-balanced bucket distribution using image sizes for even workload across workers

## 0.1

### Added

- Initial version of the task with inline FIPS compliance checking.
