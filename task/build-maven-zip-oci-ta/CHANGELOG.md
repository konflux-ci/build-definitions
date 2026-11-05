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

- Support for multiple artifact types — npm gzip tarballs alongside maven zips.
- Automatic file type detection to assign the correct OCI media type (`application/vnd.maven+zip`, `application/vnd.npm+tar+gzip`).
- `TARBALL_FILES` result listing the files pushed as OCI artifacts.
- `SBOM_SKIP_VALIDATION` parameter to optionally skip SBOM validation.
- Started tracking changes in this file.

### Changed

- **Breaking:** `IMAGE_EXPIRES_AFTER` parameter renamed to `EXPIRES_AFTER`.
- The `prepare` step no longer generates checksums or creates a zip — it expects pre-built archives from the prefetch step.

### Removed

- **Breaking:** `FILE_NAME` parameter removed (no longer applicable with multi-file support).
- **Breaking:** `PREFETCH_ROOT` parameter removed (no longer used).
