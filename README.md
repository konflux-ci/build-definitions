# build-definitions

This repository contains components that are managed by the Konflux Build Team.

This includes default Pipelines and Tasks. You need to have bootstrapped a working Konflux configuration from (see `https://github.com/redhat-appstudio/infra-deployments`) for the dev of pipelines or new tasks.

Pipelines and Tasks are delivered into Konflux via the quay organization `konflux-ci/tekton-catalog`.
Pipelines are bundled and pushed into repositories prefixed with `pipeline-` and tagged with `$GIT_SHA` (the tag will be updated with every change).
Tasks are bundled and pushed into repositories prefixed with `task-` and tagged with `$VERSION`, where `VERSION` is the task version (the tag is updated when the task file contains any change in the PR)

Currently, a set of utilities is bundled with Konflux in `quay.io/konflux-ci/appstudio-utils:$GIT_SHA` as a convenience, but tasks may be run from different per-task containers.


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
- `template-build`: contains common template used to generate `docker-build`, `fbc-builder` and other pipelines.

### Tasks

The tasks can be found in the `tasks` directories. Tasks are bundled and used by bundled pipelines. Tasks are not stored in the cluster.

#### Pushing task bundles for inner loop development

A convenient way to try out Task changes is to simply replace the task bundle reference
in a Konflux pipeline with your own task bundle.

Prerequisites:

- A repository onboarded to Konflux
- The [`tkn`](https://tekton.dev/docs/cli/) CLI
- An account in [quay.io](https://quay.io) (or other container registry)
- Any container CLI tool that has a `login` command, e.g. `podman`

How-to (example for pushing the `git-clone-oci-ta` task to quay.io):

1. Build the task bundle and push it to quay.io

    ```bash
    podman login quay.io

    tkn bundle push \
      -f task/git-clone-oci-ta/0.1/git-clone-oci-ta.yaml \
      quay.io/<USERNAME>/tekton-catalog/task-git-clone-oci-ta:my-bugfix
    ```

2. Go to <https://quay.io/USERNAME/tekton-catalog/task-git-clone-oci-ta>
   and make the repository public (in the settings)

3. Use the task bundle in a Konflux Pipeline

    ```diff
           - name: name
             value: git-clone-oci-ta
           - name: bundle
    -        value: quay.io/konflux-ci/tekton-catalog/task-git-clone-oci-ta:0.1@sha256:aab5f0f4906ba2c2a64a67b591c7ecf57018d066f1206ebc56158476e29f2cf3
    +        value: quay.io/<username>/tekton-catalog/task-git-clone-oci-ta:my-bugfix
           - name: kind
             value: task
           resolver: bundles
    ```

4. Run the pipeline with your task bundle by opening a PR in your repo

#### Trusted Artifact Task variants

With Trusted Artifacts (TA) Tasks share files via the use of archives stored in
a image repository and not using attached storage (PersistantVolumeClaims). This
has performance and usability benefits. Details can be found in
[ADR36](https://konflux-ci.dev/architecture/ADR/0036-trusted-artifacts.html).

When authoring a Task that needs to share or use files from another Task the
task author can opt to include the Trusted Artifact variant, by convention in
the `${task_name}-oci-ta` directory. Inclusion of the TA variant is mandatory
for Tasks that are part of the Trusted Artifact Pipeline variants, i.e.
Pipelines defined in the `pipelines/*-oci-ta` directories.

Authoring of a TA Task variant can be automated using the
[trusted-artifacts](task-generator/trusted-artifacts/) tool. For details on how
to use the tool consult the [it's
README](task-generator/trusted-artifacts/README.md) document.

When making changes to an existing Task that has a Trusted Artifacts variant,
make sure to run the `hack/generate-ta-tasks.sh` script to update the
`${task_name}-oci-ta` Task definition. Not doing so will fail the
[`.github/workflows/check-ta.yaml`](.github/workflows/check-ta.yaml) workflow.

### External tasks

External tasks are tasks that were built outside of build definitions.
The option to add them to our pipelines is now available by adding them to the
external-task folder in the structure of a catalog including the name and version
of the task, for example:

```
external-task/
└── rpms-signature-scan
    └── 0.2
        └── rpms-signature-scan.yaml
```

The task definition yaml only includes the reference to the task bundle in the repository:
```yaml
task_bundle: quay.io/konflux-ci/konflux-vanguard/task-rpms-signature-scan:0.2@sha256:ea256cb37e60e49bc03b9639054e696a3ddffb97a24b3c3dda64b40986fd6d01
```

A renovate rule should be added in order to update the reference of the task's bundle, [example](https://github.com/konflux-ci/build-definitions/blob/79a84deef2d95c51520dba233228517a5864926f/renovate.json#L249-L259)

Once the build-definitions CI will run and build all the tasks and pipelines it will first iterate over the external-task folder and will add these tasks to the pipelines, then, it will iterate over the internal tasks.
To avoid duplications, the external task will get prioritize over the internal one. So if a task is found both in external-task and in task, the external-task will be in use.

### StepActions

Take a look at the [Tekton documentation](https://tekton.dev/docs/pipelines/stepactions/) for more information about StepActions.

The StepActions can be found in the `stepactions` directory. StepActions are not yet bundled.

### Versioning

When a task update changes the interface (e.g., change of parameters, workspaces or results names), a new version of the task should be created.
We restructure the task definitions so that each version is maintained in its own directory. Instead of a single flat task file, the task is now versioned by placing its YAML into a version-specific folder.
Within the newly versioned YAMLs a label should be added to the tasks metadata for identifying the specific version of the task.
The folder with the new version must contain `MIGRATION.md` with instructions on how to update the current pipeline file in user's `.tekton` folder.
Since tasks are now organized by version, any pipelines that reference these tasks must be updated to point to the newly versioned path.

If the task update affects the results which are checked by [e2e tests](https://github.com/konflux-ci/e2e-tests/tree/main), 
then the corresponding e2e test code needs to be updated as well.
The main place to check for task results which are being checked by e2e is the 
[task_results.go](https://github.com/konflux-ci/e2e-tests/blob/main/pkg/utils/build/task_results.go), 
though it's good practice to check all tests in that repository.
In case the PRs handling this change get blocked by each other, consult [the guide for PR pairing](https://github.com/konflux-ci/e2e-tests/blob/main/docs/Installation.md#konflux-in-openshift-ci-and-branch-pairing) in e2e tests.

Adding a new parameter with a default value does not require a task version increase.

## Local development

Build-definitions uses various mechanisms for automatically generating Tasks, Pipelines
and other files. For example:

- Tasks can have a TA (Trusted Artifact) version.
  The TA variants can be identified by the `-oci-ta` suffix in the name.
- We also use [Kustomize](https://kustomize.io/) to generate some Tasks and Pipelines.
  Kustomize-generated resources can be identified by the existence of a `kustomization.yaml`
  file next to the Task/Pipeline yaml file.
  - Unless the kustomization file references only the Task/Pipeline yaml itself.
    Such a kustomization file is there for the sole purpose of allowing other
    Tasks/Pipelines to reference this one as a base.

The generation mechanisms each have their own script under the `hack/` directory,
but we recommend running them all at once via [hack/generate-everything.sh](hack/generate-everything.sh).

```bash
./hack/generate-everything.sh
```

## Making changes to tasks and pipelines

If your tasks or pipelines contains `kustomization.yaml`, after making changes to the tasks or pipelines, run `hack/build-manifests.sh` and
commit the generated manifests as well to the same directory (in addition to your changes).
It will help us to make sure the kustomize build of your changes is successful and nothing broken while review the changes.

In CI, `hack/verify-manifests.sh` script will verify that you have submitted the built manifests as well while sending the PR. 

## Testing

### Prerequisites
- Provisioned cluster with sufficient resources
- Deployed Konflux on the cluster (see [infra-deployments](https://github.com/redhat-appstudio/infra-deployments))

1. Set up the image repository
PipelineRuns attempt to push to cluster-internal registry `image-registry.openshift-image-registry.svc:5000` by default.
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
  QUAY_NAMESPACE=OWNER/REPOSITORY_NAME ./hack/test-build.sh https://github.com/jduimovich/spring-petclinic java-builder`.
  ```
- To run tests on predefined Git repositories and pipelines, use:
  ```
  QUAY_NAMESPACE=OWNER/REPOSITORY_NAME ./hack/test-builds.sh
  ```
- Shellspec tests can be run by invoking:
  ```
  ./hack/test-shellspec.sh`
  ```

## Testing Tasks

When updating tasks, if the tasks doesn't have tests, try to add a few tests. Currently it is not mandatory, but is recommended.
When a pull request is opened, CI will run the tests (if it exists) for the task directories that are being modified.
[Github workflow](https://github.com/konflux-ci/build-definitions/blob/main/.github/workflows/run-task-tests.yaml) runs the tests.

Tests are defined as Tekton Pipelines inside the `tests` subdirectory of the task directory. The test filenames must match `test-*.yaml` format and 
a test file should contain a single Pipeline.

E.g. to add a test pipeline for `task/git-clone/0.1` task, you can add a pipeline such as `task/git-clone/0.1/tests/test-git-clone-run-with-tag.yaml`

Refer the task under test in a test pipeline by task name. For example:
```
  - name: run-task
    taskRef:
      name: git-clone
```

### Testing scenarios where the Task is expected to fail

When testing Tasks, most tests will test a positive outcome. But sometimes it's desirable to test that a Task fails, for example when invalid data is supplied as input for the Task. But if the Task under test fails in the test Pipeline, the whole Pipeline will fail too. So we need a way to tell the test script that the given test Pipeline is expected to fail.

You can do this by adding the annotation `test/assert-task-failure` to the test pipeline object. This annotation will specify which task `(.spec.tasks[*].name)` in the pipeline is expected to fail. For example:

```
---
apiVersion: tekton.dev/v1beta1
kind: Pipeline
metadata:
  name: test-git-clone-fail-for-wrong-url
  annotations:
    test/assert-task-failure: "run-task"
```
When this annotation is present, the test script will test that the pipeline fails and also that it fails in the expected task.

### Adding Workspaces

Some tasks require one or multiple workspaces. This means that the test pipeline will also have to declare a workspace and bind it to the workspace(s) required by the task under test.

Currently, the test script will pass a single workspace named `tests-workspace` mapping to a 10Mi volume when starting the pipelinerun.
This workspace can be used in the test pipeline.

### Test Setup 

Some task tests will require setup on the kind cluster before the test pipeline can be run. Certain things can be done in a setup task step as part of the test pipeline, but others cannot. 
In order to achieve this, a `pre-apply-task-hook.sh` script can be created in the `tests` directory for a task. When the CI runs the testing, it will first check for this file. If it is found, it is executed before the test pipeline.

### Mocking commands executed in task scripts

Mocking commands is possible similar to the release service catalog repository.
For more details and example, refer [here](https://github.com/konflux-ci/release-service-catalog/blob/development/CONTRIBUTING.md#mocking-commands-executed-in-task-scripts).

### Prerequisites for running task test locally

- Upstream [konflux-ci installed](https://github.com/konflux-ci/konflux-ci?tab=readme-ov-file#bootstrapping-the-cluster) on a kind cluster
- [tkn](https://github.com/tektoncd/cli) installed
- jq installed

You can run the test script locally and to run tests for a particular task, pass the task directories as arguments, e.g.
```
./.github/scripts/test_tekton_tasks.sh task/git-clone/0.1
```
This will install the task and run all test pipelines matching `tests/test-*.yaml` under task directory.

Another option is to run one or more tests directly by specifying them as arguments:
```
./.github/scripts/test_tekton_tasks.sh tasks/git-clone/tests/test-git-clone-run-with-tag.yaml
```
It will then run only the specified test pipeline.

### Compliance

Task definitions must comply with the [Conforma](https://conforma.dev/) policies.
Currently, there are three policy configurations.

- The [all-tasks](./policies/all-tasks.yaml) policy configuration applies to all Task definitions.
- The [build-tasks](./policies/build-tasks.yaml) policy configuration applies only to build Task
  definitions.
- The [step-actions](./policies/step-actions.yaml) policy configuration applies to all StepAction
  definitions.

A build Task, e.g. one that produces a container image, must abide by both `all-tasks` and
`build-tasks` policy configurations.

## Task Migration

Task migrations allow task maintainers to introduce changes to Konflux standard
pipelines according to the task updates. By creating migrations, task
maintainers are able to add/remove/update task parameters, change task
execution order, add/remove mandatory task to/from pipelines, etc.

Historically, task maintainers write `MIGRATION.md` to notify users what changes
have to be made to the pipeline. This mechanism is not deprecated. Besides
writing the document, it is also recommended to write a migration script so that the
updates can be applied to user pipelines automatically, that is done by the
[pipeline-migration-tool](https://github.com/konflux-ci/pipeline-migration-tool).

Task migrations are Bash scripts defined in version-specific task
directories. In general, a migration consists of a series of `yq` commands that
modify pipeline in order to work with the new version of task. Developers can
do more with task migrations on the pipelines, e.g. add/review a task,
add/remove/update task parameters, change execution order of a task, etc.

### Create a migration

The following is the steps to write a migration:

- Bump task version. Modify label `app.kubernetes.io/version` in the task YAML file.
- Ensure `migrations/` directory exists in the version-specific task directory.
- Create a migration file under the `migrations/` directory. Its name is in
  form `<new task version>.sh`. Note that the version must match the bumped
  version.

The migration file is a normal Bash script file:

- It accepts a single argument. The pipeline file path is provided via this
  argument. The script must work with a Tekton Pipeline by modifying the
  pipeline definition under the `.spec` field. In practice, regardless of whether
  the pipeline definition is embedded within the PipelineRun by `pipelineSpec` or
  extracted into a separate YAML file, the migration tool ensures that the
  passed-in pipeline file contains the correct pipeline definition.
- All modifications to the pipeline must be done in-place, i.e. using `yq
  -i` to operate the pipeline YAML.
- It should be simple and small as much as possible.
- It should be idempotent as much as possible to ensure that the changes are
  not duplicated to the pipeline when run the migration multiple times.
- Pass the `shellcheck` without customizing the default rules.
- Check whether the migration is for all kinds of Konflux pipelines or not. If
  no, skip the pipeline properly in the script, e.g. skip FBC pipeline due
  to [many tasks are removed](https://github.com/konflux-ci/build-definitions/blob/main/pipelines/fbc-builder/patch.yaml)
  from template-build.yaml.
- The pipeline file path and name can be arbitrary. Please do not use the input
  value to check pipeline type or do test in `if-then-else` statement for
  conditional operations.

Here are example steps to create a migration for a task `task-a` (and oci-ta variant):

```bash
yq -i "(.metadata.labels.\"app.kubernetes.io/version\") |= \"0.2.2\"" task/task-a/0.2/task-a.yaml
mkdir -p task/task-a/0.2/migrations || :
cat >task/task-a/0.2/migrations/0.2.2.sh <<EOF
#!/usr/bin/env bash

# A migration script should find out tasks from a Pipeline by the referenced real task name

set -e
declare -r pipeline_file=${1:?missing pipeline file}

# Get task names, a same task ref may be used multiple times, task names are unique but can be changed by users
tasks_names=()

for task_refname in "task-a" "task-a-oci-ta"; do
    if yq -e ".spec.tasks[] | select(.taskRef.params[] | (.name == \"name\" and .value == \"${task_refname}\"))" "$pipeline_file" >/dev/null; then
        tasks_found="$(yq -e ".spec.tasks[] | select(.taskRef.params[] | (.name == \"name\" and .value == \"${task_refname}\")).name" "${pipeline_file}")"
        readarray -t -O ${#tasks_names[@]} tasks_names <<< "${tasks_found}"  # multiple tasks names can be returned
    fi
done

if [ ${#tasks_names[@]} -eq 0 ]; then
    echo "No tasks found"
    exit 0
fi

for task_name in "${tasks_names[@]}"; do
  # Ensure parameter is added only once whatever how many times to run this script.
  if ! yq -e ".spec.tasks[] | select( .name == \"${task_name}\" ) | .params[] | select(.name == \"pipelinerun-name\")" "$pipeline_file" >/dev/null
  then
    yq -i -e "
      (.spec.tasks[] | select( .name == \"${task_name}\" ) | .params) +=
      {\"name\": \"pipelinerun-name\", \"value\": \"\$(context.pipelineRun.name)\"}
    " "$pipeline_file"
  fi
done
EOF
```

To add a new task to the user pipelines, a migration can be created with a
fictional task update. That is to select a task, e.g. `init`, bump its version
and create a migration under `init` version-specific directory.

### Create a startup migration by the helper script

`./hack/create-task-migration.sh` is a convenient tool to help developers
create a task migration. The script handles most of the details of migration
creation. It generates a startup migration template file, then developers are
responsible for writing concrete script, which usually consists of a series of
`yq` commands, to implement the migration.

Here are a few examples:

To create a migration for the latest major.minor version of task `push-dockerfile`:

```bash
./hack/create-task-migration.sh -t push-dockerfile
```

To get a complete usage: `./hack/create-task-migration.sh -h`

### Add tasks to Konflux pipelines

Fictional task updates is a way to add tasks to Konflux pipelines. Following
is the workflow:

- Add the new task to build-definitions. Going through the whole process until
  task bundle is pushed to the registry. If the task to be added exists
  already, skip this step.

- Create a migration for the task:

  - Choose an existing task to act as a fictional update, e.g. `init`.
  - Create a migration for it:

    ```bash
    ./hack/create-task-migration.sh -t init
    ```

  - Edit the generated migration file, write script to add the task. Here is an
    example using `yq`:

    ```bash
    #!/usr/bin/env bash
    pipeline=$1
    name="<task name>"
    if ! yq -e ".spec.tasks[] | select(.name == \"${name}\")" "$pipeline" >/dev/null 2>&1
    then
      task_def="{
        \"name\": \"${name}\",
        \"taskRef\": {
          \"params\": [
            {\"name\": \"name\", \"value\": \"${name}\"},
            {\"name\": \"bundle\", \"value\": \"<bundle reference>\"},
            {\"name\": \"kind\", \"value\": \"task\"}
          ]
        },
        \"runAfter\": [\"<task name>\"]
      }"
      yq -i ".spec.tasks += ${task_def}" "$pipeline"
    fi
    ```

    Add necessary additional code to make the migration work well.

- Commit the updated task YAML file and the migration file and go through the
  review process.

The migration will be applied during next Renovate run scheduled by MintMaker.

## Task Deprecation

Often times when a new version of a task is introduced, the old version of the task may not need to
be actively maintained anymore and can be deprecated. The whole deprecation process is driven
primarily by the task maintainers who need to follow the steps outlined below to make sure Conforma
will notify Konflux users of the fact that a particular task has been deprecated and they should
migrate onto a newer version.

If you are a task maintainer here's what you need to do when deprecating a particular version of a
task:

1. Set the `build.appstudio.redhat.com/expires-on` label on the old task version.
2. Depending on whether you're adding a new version of a task or deprecating it completely set the
   `build.appstudio.redhat.com/expiry-message` on the old version. There's a default expiration
   message emitted by [Conforma](https://conforma.dev/docs/policy/tasks.html#_setting_task_expiry)
   which may be handy if you're just adding a new version.
3. Release a fresh build of the old task version with these labels (by merging the PR that sets the
   labels).
4. Move the old task to the `archived-tasks` top-level directory.

    ```bash
    $ mkdir archived-tasks/<task_name> 2>/dev/null
    $ git mv task/<task_name>/<old_version> archived-tasks/<task_name>
    ```
5. Symlink the old task from the main task location for easy historical version tracking.

    ```bash
    $ ln -s archived-tasks/<task_name>/<old_version> task/<task_name>/<old_version>
    ```
6. Optionally, introduce a new version of the task. Make sure **NOT** to reference the old
   version of the task in `kustomization.yaml` in such case as that would break CI.
7. Once the old task is past its expiration date, it can be removed from the repository completely.
