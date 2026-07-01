# Migration from 0.1 to 0.2

Removed parameters: `gitInitImage`, `verbose`, `userHome`.

New parameter: `logLevel` (default `info`) replaces `verbose`. Use `logLevel: debug` for verbose output.

## Action from users

The migration should be done automatically by renovate.
For users who don't have automatic updates, remove `gitInitImage`, `verbose`, and `userHome` parameters if present.
Replace `verbose: "true"` with `logLevel: "debug"` if needed.
