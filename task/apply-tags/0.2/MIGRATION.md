# Migration from 0.1 to 0.2

- The parameter `IMAGE_DIGEST` is added and the parameter `IMAGE` is renamed to `IMAGE_URL`.These changes will be added to build pipeline definition file automatically by script migrations/0.2.sh when MintMaker runs [pipeline-migration-tool](https://github.com/konflux-ci/pipeline-migration-tool).
