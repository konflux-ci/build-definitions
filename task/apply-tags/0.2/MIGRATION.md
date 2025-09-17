# Migration from 0.1 to 0.2

The parameter `IMAGE` was renamed to `IMAGE_URL` and parameter `IMAGE_DIGEST` was added.
These changes will be added to build pipeline definition file automatically by script migrations/0.2.sh when MintMaker runs [pipeline-migration-tool](https://github.com/konflux-ci/pipeline-migration-tool). 

If that should fail for any reason, please follow these steps:
- Search for the task named `apply-tags` in your pipeline definition file
- Rename `IMAGE` to `IMAGE_URL` in the params section
- Add new param called `IMAGE_DIGEST`. It's value should be one of the following, based on your pipeline setup (It should come from the same task as the `IMAGE` parameter):
  - $(tasks.build-oci-artifact.results.IMAGE_DIGEST)
  - $(tasks.build-image-index.results.IMAGE_DIGEST)
  - $(tasks.build-container.results.IMAGE_DIGEST)