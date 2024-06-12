# git-clone-oci-ta task

The git-clone-oci-ta Task will clone a repo from the provided url and store it as a trusted artifact in the provided OCI repository.

## Results
|name|description|
|---|---|
|SOURCE_ARTIFACT|The Trusted Artifact URI pointing to the artifact with the application source code.|
|commit|The precise commit SHA that was fetched by this Task.|
|commit-timestamp|The commit timestamp of the checkout|
|url|The precise URL that was fetched by this Task.|

