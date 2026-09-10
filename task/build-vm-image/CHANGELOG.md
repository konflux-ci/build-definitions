# Changelog

<!-- Format guidelines: https://keepachangelog.com/en/1.1.0/#how -->

## Unreleased

<!--
When you make changes without bumping the version right away, document them here.
If that's not something you ever plan to do, consider removing this section.
-->

### Fixed

- Resolve the pushed artifact manifest digest from the local manifest list
  (`buildah manifest inspect`) instead of relying on
  `buildah manifest push --digestfile`. Against some registries (e.g. quay.io)
  a `manifest push --all` of a length-1 list writes only the child manifest and
  never the list itself, leaving the digestfile empty while the push still
  exits 0. The empty digest produced a bare `$REPO@` reference and crashed the
  task with `invalid reference format`. The list only ever holds a single
  artifact manifest and the index is discarded (the tag is re-pointed at the
  child), so the locally-read child digest is authoritative and
  registry-independent. A post-push `skopeo inspect` guard confirms the child
  manifest is present on the registry before re-tagging (issue #3832).

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
