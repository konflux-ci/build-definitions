# package-operator-package task

Given a git repository, a reference (as in, tag or commit) and a path within the
repository this task will create a package-operator package.    The process of how a pko package is defined and packaged is documented
[here](https://package-operator.run/docs/guides/packaging-an-application/).
This task expects the package definition, will build it using `kubectl-package`
and push the created package to the given OCI registry destination.

## Parameters
|name|description|default value|required|
|---|---|---|---|
|SRC_PATH|Path of the directory within the repository that contains package manifest.||true|
|DST_URL|URL where to push the generated pko package to.||true|
|LABELS|Additional key=value labels to add to the OCI image.|[]|false|

## Results
|name|description|
|---|---|
|IMAGE_DIGEST|Digest of the package just built|
|IMAGE_URL|Image repository and tag where the built package was pushed|
|IMAGE_REF|Image reference of the built package|
|SBOM_BLOB_URL|Reference of SBOM blob digest to enable digest-based verification from provenance|

## Workspaces
|name|description|optional|
|---|---|---|
|source|Workspace containing the source code to build.|false|

## Additional info
