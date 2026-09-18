# Changelog

## 0.2

### Added
- **CLOUDDST-31457**: Introduced 0.2 of the `validate-fbc` task to support binaryless File-Based Catalog (FBC) operations.
- Added logic to dynamically determine the required OPM version using a helper function provided by the `konflux-test` image.

### Changed
- The target OCP version is determined by reading the com.redhat.fbc.openshift.version label, or by falling back to the base image tag if the label is missing
- The base-image verification is now bypassed for OCP 4.15+ if the identified version is fetched from label.
- The task now executes the `opm` binary directly from the `konflux-test` image, removing the dependency on extracting it from the `operator-registry` base image of the FBC fragment.

## 0.1

### Added

- The initial version of the `validate-fbc` task!