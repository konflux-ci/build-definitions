# Changelog

<!-- Format guidelines: https://keepachangelog.com/en/1.1.0/#how -->

## Unreleased

<!--
When you make changes without bumping the version right away, document them here.
If that's not something you ever plan to do, consider removing this section.
-->

*Nothing yet.*

## 0.3.1

### Added

- New result `PLATFORM`: OCI platform (`linux/<arch>`) of the disk image built by this task run. Lets `build-image-index` set the platform on each child descriptor of a multi-arch index, since disk-image OCI artifacts carry an empty config with no platform information for buildah to infer from.
- New result `IMAGE_PLATFORM_MAP`: combined `<IMAGE_REFERENCE>=linux/<arch>` entry for this task run, ready to be fanned (via `[*]`) into `build-image-index`'s `IMAGE_PLATFORM_MAP` parameter. The reference and platform are joined in-task because Tekton cannot zip two separately-aggregated result arrays produced by a matrixed `PipelineTask` (same rationale as the existing `IMAGE_REFERENCE` result).

## 0.3

### Fixed

- BREAKING: corrected `application/vnd.diskimage.qcow2.gzip` artifact type to `application/vnd.diskimage.qcow2`. The qcow2 payload was never gzip-compressed (qcow2 uses its own internal compression). Consumers matching on the old artifact type will need to update.

## 0.2.2

### Fixed

- Expanded `IMAGE_TYPE` validation to support all bootc-image-builder types: `ami`, `anaconda-iso`, `bootc-installer`, `gce`, `iso`, `ova`, `pxe-tar-xz`, `qcow2`, `raw`, `vhd`, `vmdk`. The `ami` type was rejected despite being a valid bootc-image-builder output type, breaking AWS disk image builds.
- Added push-script handling for `vmdk`, `ova`, and `pxe-tar-xz` output artifacts.
- Added explicit failure when no output artifact is found, instead of silently pushing an empty manifest.

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
