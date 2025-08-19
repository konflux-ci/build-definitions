# package-operator-package-oci-ta task

Given a git repository, a reference (as in, tag or commit) and a path within the
repository this task will create a package-operator package.    The process of how a pko package is defined and packaged is documented
[here](https://package-operator.run/docs/guides/packaging-an-application/).
This task expects the package definition, will build it using `kubectl-package`
and push the created package to the given OCI registry destination.

## Parameters
|name|description|default value|required|
|---|---|---|---|
|DST_URL|URL where to push the generated pko package to.||true|
|SOURCE_ARTIFACT|The Trusted Artifact URI pointing to the artifact with the application source code.||true|
|SRC_PATH|Path of the directory within the repository that contains package manifest.||true|

## Results
|name|description|
|---|---|
|IMAGE_DIGEST|Digest of the package just built|
|IMAGE_REF|Image reference of the built package|
|IMAGE_URL|Image repository and tag where the built package was pushed|
|SBOM_BLOB_URL|Reference of SBOM blob digest to enable digest-based verification from provenance|


## Additional info
