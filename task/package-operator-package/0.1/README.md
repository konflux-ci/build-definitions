# package-operator-package task

Given a git repository, a reference (as in, tag or commit) and a path within the repository this task will create a package-operator package.

The process of how a pko package is defined and packaged is documented [here](https://package-operator.run/docs/guides/packaging-an-application/). This task expects the package definition, will build it using `kubectl-package` and push the created package to the given OCI registry destination.

## Parameters
|name|description|default value|required|
|---|---|---|--|
|SRC_REPO_URL|URL of the git repo containing the package definition||true|
|SRC_REF|Git ref (branch, tag, commit) to use on the given src repo||true|
|SRC_PATH|Path within the check out src repo containing the package definition||true|
|DST_URL|URL where to push the generated pko package to||true|
