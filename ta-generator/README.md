# Trusted Artifacts variants generator

## Description and usage

The code in here will process a set of directions in `recipe.yaml` file and
based on that and a set of builtin conventions generate the Tekton Task
definition in YAML format.

Usage (from this directory):

    go run . path/to/recipe.yaml

The generated Trusted Artifacts Task is provided on the standard output.

## Development

To build the tool executable run `go build`, to run the tests run `go test`.
