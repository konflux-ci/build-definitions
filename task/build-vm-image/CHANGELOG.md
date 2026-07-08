# Changelog

<!-- Format guidelines: https://keepachangelog.com/en/1.1.0/#how -->

## Unreleased

<!--
When you make changes without bumping the version right away, document them here.
If that's not something you ever plan to do, consider removing this section.
-->

*Nothing yet.*

## 0.2.1

### Changed

- Replaced deprecated `quay.io/konflux-ci/buildah-task` image with `quay.io/konflux-ci/task-runner`.

## 0.2

### Added

- Started tracking changes in this file.
- SBOM support: download source container SBOM and attach it to the disk image artifact.
- New params: `SBOM_TYPE`, `SKIP_SBOM_GENERATION`.
- New result: `SBOM_BLOB_URL`.
- Multi-arch image index resolution for per-arch SBOM download.
