# Migration from 0.2 to 0.3

- All resources using task `sast-coverity-check` should be directed to use new `0.3` version.
- The `image-digest` parameter is required to be added for this task in the build pipeline. It will be added to build pipeline definition file automatically by script migrations/0.3.sh when MintMaker runs [pipeline-migration-tool](https://github.com/konflux-ci/pipeline-migration-tool).
