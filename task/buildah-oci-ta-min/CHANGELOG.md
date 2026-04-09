# Changelog

<!-- Format guidelines: https://keepachangelog.com/en/1.1.0/#how -->

## Unreleased

<!--
When you make changes without bumping the version right away, document them here.
If that's not something you ever plan to do, consider removing this section.
-->

*Nothing yet.*

## 0.9.3

### Fixed

- Version bump to stay in sync with buildah-remote-oci-ta. The remote variant now has `--fail`
  flag and error handling on the `curl` call that retrieves the SSH key from the OTP server.

## 0.9.0

### Added

New version of task forked from buildah-oci-ta 0.9.0. This task has set minimal resource requirements for testing and demo purposes.
