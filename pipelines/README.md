# build-definitions

This directory the OCI bundle with default pipelines installed for build-definitions.

Update `pipelines/release-build.sh` to set he release tag to a specific version.  

Currently set manually (v0.1, v0.1.1), but when integrated into a CI, will shift to use git commit SHA. 

This have to be updated on the infra-deployment cluster when the version is updated.

TODO - add CI automate this version bumps. 
