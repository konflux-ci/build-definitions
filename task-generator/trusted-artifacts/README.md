# Trusted Artifacts variants generator

## Description

This tool is used for the generation of trusted artifacts variants of a task.
It will process a set of directions in `recipe.yaml` file and
based on that and a set of builtin conventions generate the Tekton Task
definition in YAML format.

This tool is used by the `hack/generate-ta-tasks.sh` script.

## Usage

The tool uses only one argument - path to the `recipe.yaml` file.
These `recipe.yaml` files are stored in the task directories ending with `-oci-ta`.

Usage (from the `task-generator/trusted-artifacts` directory)
```
go run . path/to/recipe.yaml
```

The generated Trusted Artifacts Task is provided on the standard output.

Recipe defines how to transform a non-Trusted Artifacts Tekton Task definition
to a Trusted Artifacts Tekton Task definition. 

Basic recipe consists of providing a base path to the non-Trusted Artifacts Task
and declaring that the Task will either create or use Trusted Artifacts by
setting the add to `create-source`, `create-cachi2`, `use-source` and/or
`use-cachi2`.

For example:

	---
	base: ../../mytask/0.1/mytask.yaml
	add:
	  - use-source
	  - create-source

Further options can be added as needed, most commonly removal of workspace
declarations using `removeWorkspaces` and string replacements using
`replacements`.


### Configuration in recipe.yaml

The following is the list of supported options:

| Option               | Type                                             | Description |
|----------------------|--------------------------------------------------|-------------|
| `add`                | sequence of strings                              | Task Steps to add, can be one or more of `create-source`, `create-cachi2`, `use-source` or `use-cachi2` |
| `addEnvironment`     | sequence of [EnvVar]                             | Additional environment variables to add to all existing Task Steps in the non-Trusted Artifact Task |
| `additionalSteps`    | sequence of [AdditionalSteps](#additional-steps) | Additional Tekton Steps to add |
| `addParams`          | sequence of Tekton [ParamSpec]s                  | Additional Tekton Task parameters to add to the Task |
| `addResult`          | sequence of Tekton [TaskResult]s                 | Additional Tekton Task results to add to the Task |
| `addVolume`          | sequence of [Volume]s                            | Additional Volumes to add to the Task |
| `addVolumeMount`     | sequence of [VolumeMount]s                       | Additional VolumeMount to add to the Task |
| `base`               | string                                           | Relative path from `recipe.yaml` to the Task definition of the non-Trusted Artifacts Task |
| `description`        | string                                           | Description of the Trusted Artifacts Task |
| `displaySuffix`      | string                                           | Additional text to place to the value of `tekton.dev/displayName` annotation from the non-Trusted Artifacts Task to the Trusted Artifacts Task (default: `" oci trusted artifacts"`) |
| `preferStepTemplate` | boolean                                          | When `true` preference is set to configure common configuration on the `Task.spec.stepTemplate` rather than on each Task Step |
| `regexReplacements`  | map of strings keys and string values            | Perform regular expression-based replacement with keys being the regular expression and the values being the replacement, see [Replacements](#replacements) |
| `removeParams`       | sequence of strings                              | Names of Task parameters to remove |
| `removeVolumes`      | sequence of strings                              | Names of Task Volumes to remove |
| `removeWorkspaces`   | sequence of strings                              | Names of Workspaces to remove |
| `replacements`       | map of strings keys and string values            | Replacements to perform, keys will be replaced with the values |
| `suffix`             | string                                           | Additional text to place to the Task name from the non-Trusted Artifacts Task to the Trusted Artifacts Task (default: `"-oci-ta"`) |

#### Additional steps

| Option                     | Type                | Description |
|----------------------------|---------------------|-------------|
| _Any key from Tekton Step_ | Tekton [Step]       | Inline definition of a Tekton Step |
| `at`                       | number              | Step insertion point as a index of the `Task.spec.steps sequence` |

#### Replacements

Both regular expression (`regexReplacements`) and string based replacements
(`replacements`) operate on a fixed set of keys in the Task, these are:
 - Task.spec.stepTemplate.env
 - Task.spec.stepTemplate.workingDir
 - Task.spec.steps.env
 - Task.spec.steps.workingDir
 - Task.spec.steps.script

## Testing

There are various included tests in the `golden` folder. 
They use the `base.yaml` file which gets modified based on the `recipe.yaml` and is compared to the `ta.yaml`
```
go test ./...
```

[EnvVar]:
    https://kubernetes.io/docs/reference/kubernetes-api/workload-resources/pod-v1/#environment-variables
[Step]: https://tekton.dev/docs/pipelines/tasks/#defining-steps
[ParamSpec]: https://tekton.dev/docs/pipelines/tasks/#specifying-parameters
[TaskResult]: https://tekton.dev/docs/pipelines/tasks/#emitting-results
[Volume]:
    https://kubernetes.io/docs/reference/kubernetes-api/config-and-storage-resources/volume/#Volume
[VolumeMount]: https://kubernetes.io/docs/reference/kubernetes-api/workload-resources/pod-v1/#volumes-1