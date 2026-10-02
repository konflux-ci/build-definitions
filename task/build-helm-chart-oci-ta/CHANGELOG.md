# Changelog

## 0.4.0

### Changed

**BREAKING CHANGE**: Respect the version field in Chart.yaml when present.

The task now prioritizes version sources in this order:
1. CHART_VERSION parameter (full override)
2. Chart.yaml version field with timestamp as pre-release identifier (NEW)
3. Git-based calculation (fallback for repos without Chart.yaml version)

This ensures each build has a unique, semantically ordered version while
respecting user input. The timestamp prevents race conditions from concurrent
builds with the same Chart.yaml version, and enables dynamic tagging via
`{{ oci_version }}` in ReleasePlanAdmissions.

**Migration Required**: Users who currently have placeholder versions in
Chart.yaml (e.g., `version: 0.1.0`) that rely on git-based calculation must
REMOVE the version field from Chart.yaml to continue using git-based versioning.
Alternatively, set the version field to your actual product version to use the
new timestamp-based versioning.

Example: Chart.yaml `version: 1.0.0` becomes `1.0.0-1724684400` in the built
chart, which Helm stores in the `org.opencontainers.image.version` annotation.

## 0.3.1

### Fixed

Skip adding helm repositories for `file://` protocol dependencies.
Helm cannot register local filesystem paths as remote repositories, causing
`helm repo add` to fail with "could not find protocol handler for: file".
Local dependencies are resolved by `helm dependency build` directly from the
filesystem without requiring a repository entry.
