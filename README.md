# build-definitions

This repository contains components that are managed by the Konflux Build Team Green.

This includes default Pipelines and Tasks. You need to have bootstrapped a working App Studio configuration from (see `https://github.com/redhat-appstudio/infra-deployments`) for the dev of pipelines or new tasks.

Pipelines and Tasks are delivered into App Studio via the quay organization `konflux-ci/tekton-catalog`.
Pipelines are bundled and pushed into repositories prefixed with `pipeline-` and tagged with `$GIT_SHA` (the tag will be updated with every change).
Tasks are bundled and pushed into repositories prefixed with `task-` and tagged with `$VERSION`, where `VERSION` is the task version (the tag is updated when the task file contains any change in the PR)

Currently, a set of utilities is bundled with App Studio in `quay.io/konflux-ci/appstudio-utils:$GIT_SHA` as a convenience, but tasks may be run from different per-task containers.


## Building

The script `hack/build-and-push.sh` creates bundles for pipelines, tasks and the `appstudio-utils` image. Images are pushed into your quay.io repository. You will need to set `QUAY_NAMESPACE` to use this feature and be logged into quay.io on your workstation.
Once you run the `hack/build-and-push.sh`, all pipelines will come from your bundle instead of the default one installed by GitOps into the cluster.

> **Note**
>
> If you're using macOS, you need to install [GNU coreutils](https://formulae.brew.sh/formula/coreutils) before running the `hack/build-and-push.sh` script:
> ```bash
> brew install coreutils
> ```

There is an option to push all bundles to a single quay.io repository (this method is used in PR testing). It is used by setting a `TEST_REPO_NAME` environment variable. Bundle names are then specified in the container image tag, i.e., `quay.io/<quay-user>/$TEST_REPO_NAME:<bundle-name>-<tag>`

### Pipelines

The pipelines can be found in the `pipelines` directory.

- `core-services`: contains pipelines for the CI of Konflux core services e.g., `application-service` and `build-service`.
- `template-build`: contains common template used to generate `docker-build`, `fbc-builder`, `java-builder` and `nodejs-builder` pipelines.

### Tasks

The tasks can be found in the `tasks` directories. Tasks are bundled and used by bundled pipelines. Tasks are not stored in the cluster.
For quick local inner-loop-style task development, you may install new Tasks in your local namespace manually and create your pipelines, as well as the base task image, to test new functionality. Tasks can be installed into the local namespace using `oc apply -k tasks/appstudio-utils/util-tasks`.

There is a container used to support multiple sets of tasks called `quay.io/konflux-ci/appstudio-utils:GIT_SHA`. This is a single container used by multiple tasks. Tasks may also be in their own containers as well. However, many simple tasks are utilities and will be packaged for App Studio in a single container. Tasks can rely on other tasks in the system, which are co-packed in a container, allowing combined tasks (build-only vs. build-deploy) that use the same core implementations.


### StepActions

Take a look at the [Tekton documentation](https://tekton.dev/docs/pipelines/stepactions/) for more information about StepActions.

The StepActions can be found in the `stepactions` directory. StepActions are not yet bundled.

### Versioning

When a task update changes the interface (e.g., change of parameters, workspaces or results names), a new version of the task should be created. The folder with the new version must contain `MIGRATION.md` with instructions on how to update the current pipeline file in user's `.tekton` folder.

Adding a new parameter with a default value does not require a task version increase.

Task version increase must be approved by the Project Manager.

## Local development
Tasks can have a TA (Trusted Artifact) version.
The recommended workflow is to only edit the base version and let the other versions get generated automatically.
```
./hack/generate-ta-tasks.sh
```
Buildah also has a remote version, which can be generated with:
```
./hack/generate-buildah-remote.sh
```

## Testing

### Prerequisites
- Provisioned cluster with sufficient resources
- Deployed Konflux on the cluster (see [infra-deployments](https://github.com/redhat-appstudio/infra-deployments)) 

1. Set up the image repository
PipelineRuns attempt to push to `registry.redhat.io` by default. 
For testing, you will likely want to use your own Quay repository. 
Specify the Quay repository using the `QUAY_NAMESPACE` environment variable in the format `OWNER/REPOSITORY_NAME`.
2. Set up the `redhat-appstudio-staginguser-pull-secret`
   - Log in to `quay.io` using your credentials:
     ```
     podman login quay.io
     ```
     This will create an `auth.json` file in `${XDG_RUNTIME_DIR}/containers/auth.json`, which you will use to create a secret in the cluster.
   - Create the pull secret in you cluster:
     ```
     oc create secret docker-registry redhat-appstudio-staginguser-pull-secret --from-file=.dockerconfigjson=${XDG_RUNTIME_DIR}/containers/auth.json
     ```
   - Link the secret to your service account:
     ```
     oc secrets link appstudio-pipeline redhat-appstudio-staginguser-pull-secret
     ```
3. Run the tests

- To test a custom Git repository and pipeline, use `./hack/test-build.sh`. 
  
  Usage example:
  ```
  ./hack/test-build.sh https://github.com/jduimovich/spring-petclinic java-builder`.
  ```
- To run tests on predefined Git repositories and pipelines, use:
  ```
  ./hack/test-builds.sh
  ```
- Shellspec tests can be run by invoking:
  ```
  ./hack/test-shellspec.sh`
  ```

### Compliance

Task definitions must comply with the [Enterprise Contract](https://enterprisecontract.dev/) policies.
Currently, there are two policy configurations. 
- The [all-tasks](./policies/all-tasks.yaml) policy
configuration applies to all Task definitions 
- The [build-tasks](./policies/build-tasks.yaml)
policy configuration applies only to build Task definitions. 

A build Task, i.e., one that produces a
container image, must abide by both policy configurations.
