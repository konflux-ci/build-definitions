# Changelog

<!-- Format guidelines: https://keepachangelog.com/en/1.1.0/#how -->

## Unreleased

<!--
When you make changes without bumping the version right away, document them here.
If that's not something you ever plan to do, consider removing this section.
-->

### Changed

- Push the disk image as a single OCI artifact manifest directly (via `oras`)
  instead of wrapping it in a length-1 manifest list/index and pushing with
  `buildah manifest push --all`. quay's index validator returns HTTP 500 for an
  OCI index whose only child is an artifact manifest carrying a real
  (non-empty) `{architecture,os}` config, which made the manifest-list path
  impossible on quay once a real platform config was shipped. A single artifact
  manifest avoids the index entirely, still carries a real config (so
  `build-image-index` / `apply_mapping` can derive `platform.architecture`), and
  is the correct topology for a single-arch disk-image artifact. This also
  removes the `--digestfile` workaround: the digest is now obtained from
  `oras resolve`. See AIPCC-1307.

### Fixed

- Populate the disk-image artifact manifest config with `architecture`/`os`
  (via `--artifact-config`) instead of the empty OCI config (`{}`). Previously
  the child artifact manifest carried no platform data, so the resulting image
  index had `platform: null`, and downstream release tasks
  (`get-image-architectures` / `apply_mapping`) failed with
  `KeyError: 'platform'`.
- Use OCI architecture names (`amd64`/`arm64`) in the artifact manifest config
  instead of the kernel names returned by `$(arch)` on the remote builder VM
  (`x86_64`/`aarch64`). The `--artifact-config` blob is stored verbatim with no
  normalization (unlike buildah's `--arch` flag), so a non-standard value would
  otherwise reach downstream release tasks that key on `platform.architecture`.
  The architecture is now derived from the `PLATFORM` param.

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
