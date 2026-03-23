# Changelog

## 0.3

### Changed

- The task now uses `konflux-build-cli` for the build step instead of an inline bash
  implementation. This provides more robust error handling and simplified maintenance.
- When `ALWAYS_BUILD_INDEX` is `false` and multiple images are provided, the task now
  creates an image index instead of failing. The previous behavior (failing with an error)
  was not useful.
- Image reference validation is now stricter and will fail earlier for invalid formats.

### Removed

- `COMMIT_SHA` parameter (was not used by the task implementation)
- `IMAGE_EXPIRES_AFTER` parameter (was not used by the task implementation)

### Added

- Started tracking changes in this file.
