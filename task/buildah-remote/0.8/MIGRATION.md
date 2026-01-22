# Migration from 0.7 to 0.8

In version 0.8:

- The buildah image that runs the task now uses
  [konflux-ci/task-runner](https://github.com/konflux-ci/task-runner) as the base
  image and gets both the `buildah` binary and the relevant configuration from there.
  - This updates the `buildah` version from 1.41.5 to 1.42.2

## Action from users

No action needed. This update is expected to be backwards-compatible.
