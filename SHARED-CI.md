<!--
<TEMPLATED FILE!>
This file comes from the templates at https://github.com/konflux-ci/task-repo-shared-ci.
Please consider sending a PR upstream instead of editing the file directly.
-->

# 🤝 Shared CI setup for Konflux Task repos

Some of the CI scripts and workflows in this repo come from the [task-repo-shared-ci]
template repo.

All the files that come from the template repo have a `<TEMPLATED FILE!>` comment
near the top to help identify them.

## 🍏 Updating the shared CI

Use [`cruft`][cruft] to update the shared CI files to the latest template:

```bash
cruft update --skip-apply-ask --allow-untracked-files
```

Don't forget to commit the `.cruft.json` changes as well to track which
version of the templates you have.

> [!TIP]
> If you have [`uv`][uv] installed, you can run `uvx cruft` and don't need
> to install `cruft` itself.

Your repo also has an automated workflow that periodically checks for updates and
sends automated PRs. See [Shared CI Updater](#shared-ci-updater) for more details.

## 🔧 Making changes

You can edit the shared CI files if necessary, but please consider sending PRs
for the upstream [task-repo-shared-ci] templates to reduce drift and so that
others can benefit from the changes as well.

`cruft` *will* try to respect your custom patches during the update process, but
as you make more local changes you increase the chance of merge conflicts.

## 🌲 Expected repository structure

The shared scripts and workflows expect this repository to follow the
[Tekton Catalog structure][tekton-catalog-structure].

They also introduce new elements and conventions, such as the `${task_name}-oci-ta`
directories for [Trusted Artifacts](#trusted-artifacts) tasks.

For details on how the `tests` directory is used, see [Task Integration Tests](#task-integration-tests).

Putting it all together, the structure is as follows:

```text
task                                    👈 all tasks go here
├── hello                               👈 the name of a task
│   ├── CHANGELOG.md                    👈 the changelog for this task (required)
│   ├── 0.1                             👈 a specific version of the task
│   │   ├── hello.yaml                  👈 ${task_name}.yaml
│   │   ├── README.md
│   │   └── tests                       👈 Test directory
│   │       ├── test-hello.yaml         👈 Test - A Pipeline named test-*.yaml
│   │       ├── test-hello-2.yaml       👈 Test case 2
│   │       └── pre-apply-task-hook.sh  👈 Optional hook
│   └── 0.2
│       ├── hello.yaml
│       ├── migrations
│       │   └── 0.2.sh                  👈 script for migrating to 0.2
│       └── README.md
└── hello-oci-ta                        👈 ${task_name}-oci-ta for Trusted Artifacts
    ├── CHANGELOG.md
    └── 0.1
        ├── hello-oci-ta.yaml
        ├── README.md
        └── recipe.yaml                 👈 triggers auto-generation of the task yaml
```

## ☑️ CI workflows

### Checkton

- script: [`hack/checkton-local.sh`](hack/checkton-local.sh)
  - Allows running checkton locally.
- workflow: [`.github/workflows/checkton.yaml`](.github/workflows/checkton.yaml)
  - Runs ShellCheck on scripts embedded in YAML files.

Checkton is used to lint shell scripts embedded in YAML files (primarily Tekton files).
It does so by running ShellCheck. For more details, see the [checkton project](https://github.com/chmeliik/checkton)

### Task migration

- script: [`hack/create-task-migration.sh`](hack/create-task-migration.sh)
  - Creates a new migration script based on a basic template.
- script: [`hack/validate-migration.sh`](hack/validate-migration.sh)
  - Validates migration scripts.
- workflow: [`.github/workflows/check-task-migration.yaml`](.github/workflows/check-task-migration.yaml)
  - Validates migration scripts.

Task migrations allow task maintainers to introduce changes to Konflux standard
pipelines according to the task updates. By creating migrations, task
maintainers are able to add/remove/update task parameters, change task
execution order, add/remove mandatory task to/from pipelines, etc.

Task maintainers record task changes in `CHANGELOG.md`. If there is any
pipeline changes accordingly, it is also recommended to create a task migration
in order to be applied to user pipelines automatically, that is done by the
[pipeline-migration-tool](https://github.com/konflux-ci/pipeline-migration-tool).

Task migrations are Bash scripts defined in task directories. In general, a
migration consists of a series of pipeline-migration-tool `modify` subcommands
to modify pipeline YAML in order to work with the new version of
task. Developers can do more with task migrations on the pipelines,
e.g. add/remove a task, add/remove/update task parameters, change execution
order of a task, etc.

### `pmt-modify` command

`modify` is a subcommand of pipeline-migration-tool, which does in-place
modification on both Pipeline and PipelineRun definitions.

`pmt` is an alias for the pipeline-migration-tool executable command. In
migration scripts, invoke the command like this:

```bash
pmt modify -f "$pipeline_file" ...
```

> [!IMPORTANT]
> Using `yq -i` to modify pipelines has been deprecated. Task maintainers must
> invoke `pmt modify` in new migrations.

For more information about the command, please refer to [To modify Konflux
pipelines with modify] and `pmt modify --help`.

#### Create a migration

The following is the steps to write a migration:

- Bump task version. Modify label `app.kubernetes.io/version` in the task YAML file.
- Ensure `migrations/` directory exists in the task directory alongside the
  task YAML file.
- Create a migration file under the `migrations/` directory. Its name is in
  form `<new task version>.sh`. Note that the version must match the bumped
  version.

For example, to create a migration for task `hello`, migration file should be
present like this:

```
task
└── hello
    ├── hello.yaml
    └── migrations
        └── 0.2.sh
```

The migration file is a normal Bash script file:

- It accepts a single argument, which is a file path pointing to a
  Pipeline/PipelineRun file including the task bundle update.
- Use `pmt-modify` command to modify pipeline YAML.
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

Here are example steps to create a migration for a task `task-a`:

```bash
yq -i "(.metadata.labels.\"app.kubernetes.io/version\") |= \"0.2.2\"" task/task-a/0.2/task-a.yaml
mkdir -p task/task-a/0.2/migrations || :
cat >task/task-a/0.2/migrations/0.2.2.sh <<EOF
#!/usr/bin/env bash
set -e
pipeline_file=\$1

# add-param subcommand is idempotent. It does not add parameter repeatedly.
pmt modify -f "\$pipeline_file" task task-a add-param pipelinerun-name "\$(context.pipelineRun.name)"
EOF
```

> [!TIP]
> Task selector `(.spec.tasks[], .spec.pipelineSpec.tasks[])` in the above
> example makes it easy to test the migration scripts in local by passing
> Pipeline or PipelineRun YAML file. For example:
> ```bash
> bash task/hello/migrations/0.2.sh /path/to/repo/.tekton/component-a-pull.yaml`
> ```
> Note: ensure `pmt` is available in `$PATH`.

To add a new task to the user pipelines, a migration can be created with a
fictional task update. That is to select a task, bump its version
and create a migration under the task directory.

#### Create a startup migration by the helper script

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

#### Add tasks to Konflux pipelines

Fictional task updates is a way to add tasks to Konflux pipelines. Following
is the workflow:

- Add the new task to the repository. Go through the whole process until
  task bundle is pushed to the registry. If the task to be added exists
  already, skip this step.

- Create a migration for the task:

  - Choose an existing task to act as a fictional update.
  - Create a migration for it:

    ```bash
    ./hack/create-task-migration.sh -t <task name>
    ```

  - Edit the generated migration file, write script to add the task:

    ```bash
    #!/usr/bin/env bash
    pipeline=$1
    name="<task name>"
    bundle_ref="<image reference>"
    # add-task subcommand is idempotent. It does not add a task repeatedly.
    pmt add-task --run-after "<task name>" --bundle-ref "$bundle_ref" "$name" "$pipeline"
    ```

    Add necessary additional code to make the migration work well.

- Commit the updated task YAML file and the migration file and go through the
  review process.

The migration will be applied during next Renovate run scheduled by MintMaker.

### Kustomize Build

- script: [`hack/build-manifests.sh`](hack/build-manifests.sh)
  - Generates task manifest YAML files from Kustomize definitions (kustomize.yaml, patch.yaml)
- workflow: [`.github/workflows/check-kustomize-build.yaml`](.github/workflows/check-kustomize-build.yaml)
  - Checks if all task manifests are up to date (no rebuild required).

With Kustomize, Task manifests are generated and kept consistent across the
repository by composing base definitions (kustomize.yaml) with patches (patch.yaml).
This ensures that all Task YAML manifests are reproducible and remain in sync
with their source definitions.

When authoring or modifying a Task, contributors should update the corresponding
Kustomize files and regenerate the manifests rather than editing the YAML directly.
Use [`hack/build-manifests.sh`](hack/build-manifests.sh) to regenerate the manifests.

### Trusted Artifacts

- script: [`hack/generate-ta-tasks.sh`](hack/generate-ta-tasks.sh)
  - Generates Trusted Artifacts variants of Tasks. See below for more details.
- script: [`hack/missing-ta-tasks.sh`](hack/missing-ta-tasks.sh)
  - Checks that all Tasks that use workspaces have a Trusted Artifacts variant.
- workflow: [`.github/workflows/check-ta.yaml`](.github/workflows/check-ta.yaml)
  - Checks that Tasks have Trusted Artifacts variants and that those variants
    are up to date with their base Tasks.

With Trusted Artifacts (TA), Tasks share files via the use of archives stored in
an image repository and not using attached storage (PersistentVolumeClaims). This
has performance and usability benefits. For more details, see
[ADR36](https://konflux-ci.dev/architecture/ADR/0036-trusted-artifacts).

When authoring a Task that needs to share or use files from another Task, the
task author can opt to include the Trusted Artifact variant, by convention in
the `${task_name}-oci-ta` directory. This is necessary for the Task to be usable
in Pipelines that make use of Trusted Artifacts.

To author a Trusted Artifacts variant of a Task, create the `${task_name}-oci-ta`
directory, define a [`recipe.yaml`][recipe.yaml] inside the directory and generate
the TA variant using the [`hack/generate-ta-tasks.sh`](hack/generate-ta-tasks.sh)
script. See the [trusted-artifacts generator] README for more details.

#### Ignore missing Trusted Artifacts tasks

The `missing-ta-tasks` script supports an ignore file located at one of these paths
(listed in order of precedence from highest to lowest):

- `.github/.ta-ignore.yaml`
- `.ta-ignore.yaml`

```yaml
# Task paths (glob patterns) to ignore
paths:
  - task/hello/0.2/hello.yaml
  - task/another-task/*

# Workspaces that even TA-compatible Tasks can use
# (i.e. workspaces that are not used for sharing data between tasks)
workspaces:
  - netrc-auth
  - git-auth
```

### Shared CI Updater

- workflow: [`.github/workflows/update-shared-ci.yaml`](.github/workflows/update-shared-ci.yaml)

Periodically (every Sunday, by default) checks for updates in the [task-repo-shared-ci]
templates and sends automated PRs.

You can also trigger it manually from the Actions tab of your repo.

> [!NOTE]
> If you've made custom edits to your shared CI files, then the update process
> can encounter merge conflicts. When that happens, the workflow will send the
> PR anyway but with the merge conflicts included. The PR will be in draft state
> and will include a caution note (like this one, but red) with instructions.
>
> If your repository uses Renovate for automated dependency updates, that may increase
> the chance of merge conflicts. See [Conflicts with Renovate](#conflicts-with-renovate)
> for the solution.

#### Updater requirements

- Install your organization's updater GitHub app in your repository. If the app
  doesn't exist yet, an administrator can follow the [instructions](#set-up-the-github-app)
  to create it.
  - If your repository is in <https://github.com/konflux-ci>, use the [konflux-ci-shared-ci-updater]
    app. The [build-maintainers] team can provide the values for the secrets below.
- In the repository settings (`Secrets and variables` > `Actions`), add the required
  secrets. Ask an administrator to provide their values:
  - `SHARED_CI_UPDATER_APP_ID` - the ID of the updater GitHub app
  - `SHARED_CI_UPDATER_PRIVATE_KEY` - plaintext content of the private key
    for the updater GitHub app
- Add a branch protection rule for the main branch in the repository. Enable the
  `Require a pull request before merging` setting with at least 1 required approval.
  This is not strictly required, but helps reduce the potential consequences if the
  GitHub app secrets were leaked.

> [!NOTE]
> It may be tempting to make the secrets organization-wide, to avoid having to set
> them individually for each repo. But consider the security implications - more
> repos with access to the secrets means more chances for an attacker to steal them.

#### Updater GitHub app

The update workflow uses the credentials of a GitHub app to create pull requests,
rather than the default [`GITHUB_TOKEN`][GITHUB_TOKEN]. There are two reasons:

1. PRs created using `GITHUB_TOKEN` cannot trigger `on: pull_request` or `on: push`
   workflows
2. It's not possible to grant `GITHUB_TOKEN` the permission to edit `.github/workflows/`
   files

Since the shared CI updater is *all about* workflows, it needs to use app credentials
to avoid those restrictions.

##### Set up the GitHub app

1. Go to your organization or user settings on GitHub
2. Go to `Developer settings` > `GitHub Apps`
3. Click `New GitHub App`.
4. Configure the app:
   - **GitHub App name**: e.g. `${org_name} shared CI updater`
   - **Homepage URL**: <https://github.com/konflux-ci/task-repo-shared-ci/blob/main/SHARED-CI.md#shared-ci-updater>
   - **Webhook**: uncheck the `☑️ Active` option
   - **Permissions**:
     - **Repository permissions**:
        - Contents: `Read and write`
        - Pull requests: `Read and write`
        - Workflows: `Read and write`
5. On the app's settings page, copy the App ID number and generate a private key.
   Store the private key somewhere safe. Each repo that wants to use the updater
   will need this key.

#### Conflicts with Renovate

If your repository uses [Renovate], you could frequently get merge conflicts
during the Shared CI updates, because your repository gets GitHub Actions updates
at a different rate than the upstream [task-repo-shared-ci] repository.

To avoid that, your repo gets the [`hack/renovate-ignore-shared-ci.sh`](hack/renovate-ignore-shared-ci.sh)
script. Run this script during the [onboarding process] to add all the Shared CI
workflows to the [`ignorePaths`][renovate-ignorepaths] in your `renovate.json`.
Afterwards, any time the updater workflow brings in a new workflow file, it will
run the script to automatically update `renovate.json`.

This ensures your Shared CI workflows follow the GitHub Actions versions defined
in the upstream reposistory and avoids unnecessary merge conflicts.

### Task Validation and Integration Tests

- workflow: [`.github/workflows/run-task-tests.yaml`](.github/workflows/run-task-tests.yaml)
- tests script: [`.github/scripts/test_tekton_tasks.sh`](.github/scripts/test_tekton_tasks.sh)
- validation script: [`.github/scripts/check_tekton_tasks.sh`](.github/scripts/check_tekton_tasks.sh)

To ensure all Tekton Tasks are well-formed and valid, a single `Run Task Tests` workflow is executed on every pull request that modifies files in the `task/` directory.

This workflow is designed to be efficient by following a two-stage logic:

1. `Syntax Validation`
2. `Integration Tests`

#### How to Add a Test

1. Create a `tests` directory inside the task's versioned folder.  

2. Inside the `tests` directory, create a test file named `test-*.yaml` (for example, `test-hello.yaml`).  
   - The script **automatically** discovers tests based on this naming convention.  

3. The file must define a Tekton `kind: Pipeline` object.  

4. The Pipeline must declare a workspace named exactly `tests-workspace`.  
   - The test script will **automatically** provide storage for this workspace when it runs the pipeline.  

5. Optionally, add a `pre-apply-task-hook.sh` to the `tests` directory.

#### Example Structure

```plaintext
task
└── hello
    └── 0.1
        ├── hello.yaml
        └── tests                         👈 Test directory
            └── test-hello.yaml           👈 Test - A Pipeline named test-*.yaml
            └── test-hello-2.yaml         👈 Test case 2
            └── pre-apply-task-hook.sh    👈 Optional hook
```

#### Using a `pre-apply-task-hook.sh`

In some cases, your Task may require certain Kubernetes resources, like **Secrets** or **ConfigMaps**, to exist in the namespace before the Task itself is applied to the cluster.

To handle this, you can create an optional shell script named `pre-apply-task-hook.sh` and place it inside the `tests` directory.

If this script exists, the test runner will execute it **after creating the test namespace but before applying the task**.
This allows the hook to dynamically modify the task's definition before it is applied. For example, to lower/remove resource requests and limits for a constrained test environment.

The script receives two arguments:

- `$1`: The path to a temporary copy of the task's YAML file.  
- `$2`: The name of the temporary test namespace where the test will run.  

<details>
<summary><b>Click to see an example <code>pre-apply-task-hook.sh</code></b></summary>

This script removes comupteResources and creates a dummy docker config secret that a task might need for registry authentication.

```bash
#!/bin/bash

# This script is called before applying the task to set up required resources.
TASK_COPY="$1"
TEST_NS="$2"

# Remove computeResources - allows tasks with high resource requirements
# to run in a resource-constrained test environment (e.g., local Kind cluster)
echo "Removing computeResources for task: $1"
yq -i eval '.spec.steps[0].computeResources = {}' $1
yq -i eval '.spec.steps[1].computeResources = {}' $1

# Create a dummy docker config secret for registry authentication
echo '{"auths":{}}' | kubectl create secret generic dummy-secret \
  --from-file=.dockerconfigjson=/dev/stdin \
  --type=kubernetes.io/dockerconfigjson \
  -n "$TEST_NS" --dry-run=client -o yaml | kubectl apply -f - -n "$TEST_NS"

echo "Pre-requirements setup complete for namespace: $TEST_NS"

```

</details>  

### Tekton Security Task Lint

To enforce secure CI practices, we lint all Tekton Tasks on every pull request using the `task-lint.yaml` workflow.

#### Purpose

This check **disallows using `$(params.*)` variable substitution directly within a `script` block** of a Tekton Task.

Using `$(params.*)` directly in a script creates a security flaw. Tekton performs a raw text replacement of the parameter placeholder before the script is executed. This means if a parameter's value contains malicious shell commands, they will be run, leading to **arbitrary code execution**.

For more details and guidance on fixing the issue, see the [Tekton recommendations](https://github.com/tektoncd/catalog/blob/main/recommendations.md#dont-use-interpolation-in-scripts-or-string-arguments)

### Versioning

- script: [`hack/versioning.py`](hack/versioning.py)
  - The `check` subcommand checks versioning requirements for new and modified Tasks
  - The `new-changelog` subcommand creates basic `CHANGELOG.md`s for the specified Tasks
- workflow: [`.github/workflows/versioning.yaml`](.github/workflows/versioning.yaml)
  - Runs the `check` subcommand for PRs

#### Versioning requirements

1. Tasks must have the `app.kubernetes.io/version` label

    ```yaml
    metadata:
      labels:
        app.kubernetes.io/version: "0.1.0"
    ```

    1. The version label must be in the form `x.y` or `x.y.z`, where `x y z` are integers

2. Tasks must have a CHANGELOG.md at `task/${task_name}/CHANGELOG.md`.
   For details about the format, see [ADR 54: CHANGELOG.md format].
3. When modifying existing Tasks:
    1. If you want the change to get released, update the version label.
       Otherwise, CI may skip building the Task.
    2. If the change is relevant to users, update the CHANGELOG.md.
       If you're not updating the version label, update the `Unreleased` section.

Check versioning requirements for the files that got modified/added between the
base revision (defaults to `main`) and your current HEAD:

```bash
hack/versioning.py check
```

> [!NOTE]
> When processing existing Tasks, the script treats most violations as warnings,
> not errors. Some of the requirements are new, so the check aims to inform about
> them but not to block PRs from getting merged.
>
> Requirements 3.1. and 3.2. are always only warnings. The goal is to remind the
> contributor how versioning is done but leave the freedom to make changes without
> releasing them right away.

#### Adding `CHANGELOG.md`s

Add CHANGELOG.md for a single Task:

```bash
hack/versioning.py new-changelog task/hello/
```

Add CHANGELOG.md for all Tasks that don't have one:

```bash
hack/versioning.py new-changelog task/
```

> [!NOTE]
> The script makes no attempt to retroactively document the changes in each Task version.
> The script simply marks the current version as the one that started tracking changes
> in CHANGELOG.md. If the highest found version is `<=0.1.0`, it instead marks this
> as the initial version of the Task.

[task-repo-shared-ci]: https://github.com/konflux-ci/task-repo-shared-ci
[onboarding process]: https://github.com/konflux-ci/task-repo-shared-ci?tab=readme-ov-file#-onboarding
[cruft]: https://cruft.github.io/cruft
[uv]: https://docs.astral.sh/uv/
[recipe.yaml]: https://github.com/konflux-ci/build-definitions/tree/main/task-generator/trusted-artifacts#configuration-in-recipeyaml
[trusted-artifacts generator]: https://github.com/konflux-ci/build-definitions/tree/main/task-generator/trusted-artifacts
[GITHUB_TOKEN]: https://docs.github.com/en/actions/concepts/security/github_token
[tekton-catalog-structure]: https://github.com/tektoncd/catalog?tab=readme-ov-file#catalog-structure
[Renovate]: https://docs.renovatebot.com/
[renovate-ignorepaths]: https://docs.renovatebot.com/configuration-options/#ignorepaths
[ADR 54: CHANGELOG.md format]: https://github.com/konflux-ci/architecture/blob/main/ADR/0054-task-versioning.md#changelogmd-format
[To modify Konflux pipelines with modify]: https://github.com/konflux-ci/pipeline-migration-tool?tab=readme-ov-file#to-modify-konflux-pipelines-with-modify
[konflux-ci-shared-ci-updater]: https://github.com/apps/konflux-ci-shared-ci-updater
[build-maintainers]: https://github.com/orgs/konflux-ci/teams/build-maintainers
