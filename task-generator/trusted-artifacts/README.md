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

## Testing

There are various included tests in the `golden` folder. 
They use the `base.yaml` file which gets modified based on the `recipe.yaml` and is compared to the `ta.yaml`
```
go test ./...
```