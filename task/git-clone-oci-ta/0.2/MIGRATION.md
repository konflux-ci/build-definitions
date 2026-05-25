# Migration from 0.1 to 0.2

## What changed

- **Removed parameters:** `gitInitImage`, `verbose`, `userHome`.
- **New parameter:** `logLevel` (default `info`) replaces `verbose`. Valid values: `debug`, `info`, `warn`, `error`.
- **Image changed:** The task now uses `konflux-build-cli` instead of the previous `git-clone` image.
- **Step consolidation:** The separate `symlink-check` step has been merged into the `clone` step. Symlink checking is now handled internally by the Go binary.

## Action from users

The migration should be done automatically by renovate.
For users who don't have automatic updates, remove `gitInitImage`, `verbose`, and `userHome` parameters if present.
Replace `verbose: "true"` with `logLevel: "debug"` if needed.
