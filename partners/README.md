# Partner Tekton Task submission process

Partners can submit their Tekton Task in [build-definitions](https://github.com/redhat-appstudio/build-definitions) repository by sending a pull request.

build-definitions repository CI job will validate the PR against a [set of checks](#checks).

build-definitions repository maintainers need to approve and merge the pull request before the Task can be used.

For more information, please refer to the [ADR](https://github.com/redhat-appstudio/book/blob/main/ADR/0021-partner-tasks.md).

### How to submit a Task?

Create your Task YAML and put it inside a directory of structure `partners/<task_name>/<task_version>/<task_name>.yaml` and 
also include an `OWNERS` file inside the Task directory `partners/<task_name>/OWNERS`

For example, if your Task name is `my_task` and the version of your Task is `0.1`, your Task YAML and OWNERS file locations will be `partners/my_task/0.1/my_task.yaml` and `partners/my_task/OWNERS`

Send a pull request to the [build-definitions](https://github.com/redhat-appstudio/build-definitions) repository containing your Task YAML and OWNERS file.

### How to debug the CI failures in my submitted Task?

Check the logs of the `check-partner-tasks` Task in the `build-definitions-pull-request` PR check.
If you see the Task `yaml-lint-check` has failed, then your Task YAML contains yaml-lint errors.

### Checks

Task is validated against the following mandatory checks:
* Task follows the correct directory structure and includes OWNERS file (This check is a prerequisite for other checks to be continued)
* Task is not using any privilege escalations
* Task schema is a valid one i.e. the Task resource can be applied in the Openshift cluster

## FAQs

### Can I validate the Task locally?

Yes, you can also validate your Task by running the script `hack/check-partner-tasks.sh` in your local clone. 
Make sure you have the `oc` client installed and access to an Openshift cluster.
Log in to the Openshift cluster first before running the script, otherwise Task schema validation will be ignored.

### Can partner engineers revoke a Task?

Yes, they can also submit a pull request removing the Task directory from `partners` directory.
Before sending the pull request make sure that revoking a Task will not impact any user's pipeline.
build-definitions repository maintainers will review and merge the pull request.

