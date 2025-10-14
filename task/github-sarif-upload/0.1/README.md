# GitHub SARIF Upload Task

This Tekton task downloads SARIF artifacts from container images and uploads them to GitHub using CodeQL CLI, making them visible in the GitHub Security tab.

## Overview

The task discovers and downloads SARIF files from container images using ORAS, then uploads them to GitHub using CodeQL CLI. This allows security findings to be displayed in GitHub's Security tab alongside other security insights.

## Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `GITHUB_REPOSITORY` | string | Yes | - | GitHub repository in format `owner/repo` |
| `GITHUB_REF` | string | Yes | - | Git reference (branch or tag) for the scan results |
| `GITHUB_SHA` | string | Yes | - | Git commit SHA for the scan results |
| `image-url` | string | Yes | - | Image URL containing SARIF artifacts |
| `image-digest` | string | Yes | - | Digest of the image containing SARIF artifacts |

## Results

| Result | Description |
|--------|-------------|
| `TEST_OUTPUT` | Tekton task test output in JSON format |

## Prerequisites

1. **GitHub Secret**: A secret named `github` with a `token` key containing a GitHub fine-grained token with the `security_events` scope
2. **Container Image with SARIF Artifacts**: An image containing SARIF artifacts attached as OCI artifacts
3. **Repository Access**: The token must have access to the target repository


## Usage Example

```yaml
apiVersion: tekton.dev/v1
kind: TaskRun
metadata:
  name: upload-sarif-to-github
spec:
  taskRef:
    name: github-sarif-upload
  params:
    - name: GITHUB_REPOSITORY
      value: "myorg/myrepo"
    - name: GITHUB_REF
      value: "refs/heads/main"
    - name: GITHUB_SHA
      value: "abc123def456"
    - name: image-url
      value: "quay.io/myorg/myimage"
    - name: image-digest
      value: "sha256:a60fcbaa34a5d309091165175e357054a062eb4307482ac132e5e39371136371"
```

## Integration with Other Tasks

This task is designed to work with other security scanning tasks that attach SARIF artifacts to container images, such as:

- `sast-coverity-check-oci-ta`
- `sast-snyk-check-oci-ta`
- `sast-unicode-check-oci-ta`

Example pipeline integration:

```yaml
apiVersion: tekton.dev/v1
kind: Pipeline
metadata:
  name: security-scan-pipeline
spec:
  tasks:
    - name: run-security-scan
      taskRef:
        name: sast-snyk-check-oci-ta
      params:
        - name: image-url
          value: $(params.image-url)
        - name: image-digest
          value: $(params.image-digest)
    - name: upload-to-github
      taskRef:
        name: github-sarif-upload
      runAfter:
        - run-security-scan
      params:
        - name: GITHUB_REPOSITORY
          value: $(params.GITHUB_REPOSITORY)
        - name: GITHUB_REF
          value: $(params.GITHUB_REF)
        - name: GITHUB_SHA
          value: $(params.GITHUB_SHA)
        - name: image-url
          value: $(params.image-url)
        - name: image-digest
          value: $(params.image-digest)
```

## GitHub Security Tab

Once uploaded, the SARIF results will appear in the GitHub Security tab under "Code scanning alerts". Users can:

- View all security findings in one place
- Track the status of security issues
- Set up notifications for new findings
- Integrate with GitHub's security features

## Behavior

### No SARIF Artifacts Found
If no SARIF artifacts are found in the specified image, the task will:
- Complete successfully (exit code 0)
- Generate a `TEST_OUTPUT` result indicating no artifacts were found
- Not attempt to upload anything to GitHub

## Limitations

- GitHub has a 10MB limit for SARIF file uploads
- Processing time varies based on file size and complexity
- Rate limits apply to GitHub API calls
- Only supports GitHub repositories (not GitLab, etc.)
