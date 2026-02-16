# Changelog

<!-- Format guidelines: https://keepachangelog.com/en/1.1.0/#how -->

## Unreleased

<!--
When you make changes without bumping the version right away, document them here.
If that's not something you ever plan to do, consider removing this section.
-->

*Nothing yet.*

## 0.8.3

### Fixed

- Platform build arguments (BUILDPLATFORM, TARGETPLATFORM) now correctly include CPU variant
  for ARM architectures (e.g., `linux/arm/v7` or `linux/arm64/v8` instead of just `linux/arm`
  or `linux/arm64`).

## 0.8.2

### Changed

- The task now makes sure that only RPMs that match the architecture being built are
  passed to the `buildah bud` command. It also removes the same packages from the
  Hermeto SBOM to more accurately represent the build.
  This change should be a noop for this task, but it was added here so that the
  auto-generated `buildah-remote` task would benefit from it.

## 0.8.1

### Added

- The buildah task now supports injecting ENV variables into the dockerfile
  through the `ENV_VARS` array parameter.

## 0.8

### Changed

- The buildah image that runs the task now uses
  [konflux-ci/task-runner](https://github.com/konflux-ci/task-runner) as the base
  image and gets both the `buildah` binary and the relevant configuration from there.
  - This updates the `buildah` version from 1.41.5 to 1.42.2

## 0.7.1

### Added

- Started tracking changes in this file.
