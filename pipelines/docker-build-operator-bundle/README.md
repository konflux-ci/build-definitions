# docker-build-operator-bundle pipeline

This pipeline is ideal for building operator bundle images from a Containerfile while reducing network traffic.

_Uses `buildah` to create a container image. It also optionally creates a source image and runs some build-time tests. EC will flag a violation for [`trusted_task.trusted`](https://enterprisecontract.dev/docs/ec-policies/release_policy.html#trusted_task__trusted) if any tasks are added to the pipeline.
This pipeline is pushed as a Tekton bundle to [quay.io](https://quay.io/repository/konflux-ci/tekton-catalog/pipeline-docker-build-operator-bundle?tab=tags)_


## Parameters
|name|description|default value|required|
|---|---|---|---|
|git-url|Source Repository URL||true|
|revision|Revision of the Source Repository|""|false|
|output-image|Fully Qualified Output Image||true|
|path-context|Path to the source code of an application's component from where to build image.|.|false|
|dockerfile|Path to the Dockerfile inside the context specified by parameter path-context|Dockerfile|false|
|rebuild|Force rebuild image|false|false|
|skip-checks|Skip checks against built image|false|false|
|hermetic|Execute the build with network isolation|false|false|
|prefetch-input|Build dependencies to be prefetched by Cachi2|""|false|
|image-expires-after|Image tag expiration time, time values could be something like 1h, 2d, 3w for hours, days, and weeks, respectively.|""|false|
|build-source-image|Build a source image.|false|false|
|build-image-index|Add built image into an OCI image index|false|false|
|build-args|Array of --build-arg values ("arg=value" strings) for buildah|[]|false|
|build-args-file|Path to a file with build arguments for buildah, see https://www.mankier.com/1/buildah-build#--build-arg-file|""|false|
|privileged-nested|Whether to enable privileged mode, should be used only with remote VMs|false|false|

## Results
|name|description|
|---|---|
|IMAGE_URL||
|IMAGE_DIGEST||
|CHAINS-GIT_URL||
|CHAINS-GIT_COMMIT||

## Workspaces
|name|description|optional|
|---|---|---|
|workspace||false|
|git-auth||true|
|netrc||true|
