# package-operator-package task

Given a git repository, a reference (as in, tag or commit) and a path within the repository this task will create a package-operator package.

The process of how a pko package is defined and packaged is documented [here](https://package-operator.run/docs/guides/packaging-an-application/). This task expects the package definition, will build it using `kubectl-package` and push the created package to the given OCI registry destination.

## Parameters
|name|description|default value|required|
|---|---|---|--|
|PACKAGE_PATH|File path the package manifest is in||true|
|SBOM_SRC|Source that is being specified in the SBOM pushed alongside the package||true|
|DST_URL|URL where to push the generated pko package to||true|
