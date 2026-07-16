# Changelog

<!-- Format guidelines: https://keepachangelog.com/en/1.1.0/#how -->

## Unreleased

<!--
When you make changes without bumping the version right away, document them here.
If that's not something you ever plan to do, consider removing this section.
-->

*Nothing yet.*

## 0.1.1

### Fixed

- Replaced expired `release-service-utils` image reference with a digest-pinned
  reference. The previous tag (`2f93b7ed`) was deleted from Quay.io, breaking
  the `create-modelcar-base-image` step.

### Added

- Started tracking changes in this file.
