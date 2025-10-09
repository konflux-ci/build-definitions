# verify-source task

The verify-source Task verifies the SLSA source level of a git commit
by checking for a Verification Summary Attestation (VSA) stored as a
git note. This task does not explicitly clone the repository - it performs
the verification using the sourcetool verifycommit command.

WARNING: This task uses source-tool (https://github.com/slsa-framework/source-tool)
which is currently a proof-of-concept and under active development. It should
not be used in production environments. It supports GitHub and GitLab repositories,
and may encounter API rate limits without authentication.


## Parameters
|name|description|default value|required|
|---|---|---|---|
|url|Repository URL to verify.||true|
|revision|Commit SHA to verify.||true|

## Results
|name|description|
|---|---|
|SLSA_SOURCE_LEVEL_ACHIEVED|The SLSA source level achieved by this commit|
|TEST_OUTPUT|JSON formatted test results for SLSA verification|

## Workspaces
|name|description|optional|
|---|---|---|
|basic-auth|A Workspace containing a token file for API authentication. The workspace should contain a file named 'token' with a GitHub personal access token, GitLab personal access token, or other authentication token. The task will automatically set the appropriate environment variable (GITHUB_TOKEN or GITLAB_TOKEN) based on the repository host. This is used to avoid rate limiting when accessing the API. Binding a Secret to this Workspace is strongly recommended over other volume types. |true|

## Additional info

### API Authentication

To avoid API rate limits, you can provide an authentication token via the `basic-auth` workspace. The task automatically detects the repository host and sets the appropriate environment variable (`GITHUB_TOKEN` for GitHub, `GITLAB_TOKEN` for GitLab).

**Create a secret with your token:**

```bash
# For GitHub
kubectl create secret generic git-token \
  --from-literal=token=ghp_yourGitHubTokenHere

# For GitLab
kubectl create secret generic git-token \
  --from-literal=token=glpat-yourGitLabTokenHere
```

**Use the secret in your pipeline:**

```yaml
apiVersion: tekton.dev/v1
kind: TaskRun
metadata:
  name: verify-source-example
spec:
  taskRef:
    name: verify-source
  params:
    - name: url
      value: https://github.com/slsa-framework/source-tool
    - name: revision
      value: 134593d9158efd253e979e2e8d87b939945d091e
  workspaces:
    - name: basic-auth
      secret:
        secretName: git-token
```

The task will automatically detect the `token` file in the workspace and set the appropriate environment variable based on the repository URL.
