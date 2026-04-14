# Changelog

<!-- Format guidelines: https://keepachangelog.com/en/1.1.0/#how -->

## Unreleased

<!--
When you make changes without bumping the version right away, document them here.
If that's not something you ever plan to do, consider removing this section.
-->

*Nothing yet.*

## 0.3.1

- Added `enable-package-registry-proxy` parameter to enable use of the package registry proxy when prefetching dependencies.
- Added `SERVICE_CA_TRUST_CONFIG_MAP_NAME` and `SERVICE_CA_TRUST_CONFIG_MAP_KEY` parameters to mount the OpenShift service CA for verifying TLS connections to in-cluster services such as the package registry proxy.

## 0.3

- Removed deprecated `dev-package-managers` parameter.
- Switched from bash implementation to Konflux Build CLI.

## 0.2

### Added

- Started tracking changes in this file.
