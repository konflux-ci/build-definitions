# build-definitions

This repository contains components that are installed or managed by the managed CI and Build Team.

This includes default Pipelines and Tasks. You need to have bootstrapped a working appstudio configuration from (see `https://github.com/redhat-appstudio/infra-deployments`) for the dev of pipelines or new tasks.

Pipelines are delivered into App Studio via `quay.io/redhat-appstudio/build-templates-bundle:$GIT_SHA` (the tag will be updated every change)

Tasks are delivered into App Studio via `quay.io/redhat-appstudio/appstudio-tasks`. Where tasks are bundled and pushed into tag in format `${VERSION}-${PART}` where VERSION is the same as pipelines bundle version and PART is sequence number. Tasks are grouped by 10 tasks per bundle.

Currently a set of utilities are bundled with App Studio in `quay.io/redhat-appstudio/appstudio-utils:$GIT_SHA` as a convenience but tasks may be run from different per-task containers in future.

## Building

Script `hack/build-and-push.sh` creates bundles for pipelines, tasks and create appstudio-utils image. Images are pushed into your quay.io repository. You will need to set `MY_QUAY_USER` to use this feature and be logged into quay.io on your workstation.
Once you run the `hack/build-and-push.sh` all pipelines will come from your bundle instead of from the default installed by gitops into the cluster.

### Pipelines

The pipelines can be found in the `pipelines` directories.

#### Gitops Mode

Replace the file `https://github.com/redhat-appstudio/infra-deployments/blob/main/components/build/build-templates/bundle-config.yaml` in your own fork (dev mode). This will sync to the cluster and all builds-definitions will come from the bundle you configure.

Please test in _gitops mode_ when doing a new release into staging as it will be the best way to ensure that the deployment will function correctly when deployed via gitops.

### Tasks

The tasks can be found in the `tasks` directories. Tasks are bundled and used by bundled pipelines. Tasks are not stored in the Cluster.
For quick local innerloop style task development, you may install new Tasks in your local namespace manually and create your pipelines as well as the base task image to test new function. Tasks can be installed into local namespace using `oc apply -k tasks/appstudio-utils/util-tasks`.

There is a container which is used to support multiple set of tasks called `quay.io/redhat-appstudio/appstudio-utils:GIT_SHA` , which is a single container which is used by multiple tasks. Tasks may also be in their own container as well however many simple tasks are utilities and will be packaged for app studio in a single container. Tasks can rely on other tasks in the system which are co-packed in a container allowing combined tasks (build-only vs build-deploy) which use the same core implementations.

## Release

Release is done by setting env variable `MY_QUAY_USER=redhat-appstudio`, `BUILD_TAG=$(git rev-parse HEAD)` and running `hack/build-and-push.sh`.
