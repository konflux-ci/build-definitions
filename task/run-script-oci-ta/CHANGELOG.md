# Changelog

<!-- Format guidelines: https://keepachangelog.com/en/1.1.0/#how -->

## Unreleased

*Nothing yet.*

## 0.1.3

### Added

- New optional `ADDITIONAL_SECRET` parameter to mount a Kubernetes secret into the
  script container at `/var/run/secrets/additional-secret`. Useful for passing
  registry credentials, AWS keys, or other tokens the script needs at runtime.

## 0.1.2

### Changed

- Replaced deprecated `quay.io/konflux-ci/buildah-task` image with `quay.io/konflux-ci/task-runner`.

## 0.1.1

### Added

- Now also supports prefetch task versions that output a `prefetch.env` file
  instead of `cachi2.env` (prefetch task version 0.3.1 outputs both, a future
  version will drop `cachi2.env`).
- Started tracking changes in this file.
