# build-helm-chart-oci-ta task

The task packages and pushes a Helm chart to an OCI repository.
As Helm charts require to have a semver-compatible version to be packaged, the
task relies on git tags in order to determine the chart version during runtime.

The task computes the version based on the git commit SHA distance from the latest
tag prefixed with the value of TAG_PREFIX. The value of that tag will be used as
the version's X.Y values, and the Z value will be computed by the commit's distance
from the tag, followed by an abbreviated SHA as build metadata.

The task also supports image substitution in the chart templates. Use the IMAGE_MAPPINGS
parameter to specify source images to be replaced with target images and tags.

Version 0.2 includes improved digest extraction from skopeo copy operations.

## Parameters
|name|description|default value|required|
|---|---|---|---|
|CA_TRUST_CONFIG_MAP_KEY|The name of the key in the ConfigMap that contains the CA bundle data.|ca-bundle.crt|false|
|CA_TRUST_CONFIG_MAP_NAME|The name of the ConfigMap to read CA bundle data from.|trusted-ca|false|
|CHART_CONTEXT|Path relative to SOURCE_CODE_DIR where the chart is located|dist/chart/|false|
|COMMIT_SHA|Git commit sha to build chart for||true|
|IMAGE_MAPPINGS|JSON array of image mappings to substitute in chart templates. Format: [{"source": "localhost/my/repo", "target": "quay.io/myorg/myapp"}] Source images will be replaced with target images in all YAML files in templates/. The task automatically appends the tag format: VERSION_SUFFIX-COMMIT_SHA (or just COMMIT_SHA if VERSION_SUFFIX is empty).|[]|false|
|IMAGE|Full image reference with tag (e.g., quay.io/redhat-user-workloads/konflux-vanguard-tenant/caching/squid:on-pr-{{revision}})||true|
|SOURCE_ARTIFACT|The Trusted Artifact URI pointing to the artifact with the application source code.||true|
|SOURCE_CODE_DIR|Path relative to the workingDir where the code was pulled into|source|false|
|TAG_PREFIX|An identifying prefix on which the version tag is to be matched|helm-|false|
|VALUES_FILE|Name of the values file to process for image substitution (e.g., values.yaml, values-prod.yaml)|values.yaml|false|
|VERSION_SUFFIX|A suffix to be added to the version string|""|false|

## Results
|name|description|
|---|---|
|IMAGE_DIGEST|Digest of the OCI-Artifact just built|
|IMAGE_URL|OCI-Artifact repository and tag where the built OCI-Artifact was pushed|


## Additional info

## Features

- **Chart Packaging**: Packages Helm charts with semver-compatible versioning
- **OCI Push**: Pushes packaged charts to OCI registries
- **Image Substitution**: Replaces source images with target images in chart templates
- **Git-based Versioning**: Uses git tags to determine chart versions
- **Trusted Artifacts**: Uses trusted artifacts for source code access

## Image Substitution

The task supports replacing source images with target images in chart templates before packaging. This is useful when you have placeholder images in your chart templates that need to be replaced with actual built images.

### Image Mappings Format

The `IMAGE_MAPPINGS` parameter accepts a JSON array of mapping objects:

```json
[
  {
    "source": "localhost/my/repo",
    "target": "quay.io/myorg/myapp:on-pr-{{revision}}"
  },
  {
    "source": "localhost/another/repo",
    "target": "quay.io/myorg/another-app:on-pr-{{revision}}"
  }
]
```

### How It Works

1. **Source Images**: These are the placeholder images in your chart templates
   (e.g., `localhost/my/repo`)
2. **Target Images**: These are the registry/repository names without tags
   (e.g., `quay.io/myorg/myapp`)
3. **Substitution**: The task finds all YAML files in the `templates/` directory and
   the specified values file, then replaces source images with target images (with
   standardized tags)

### Supported Image Formats

The substitution handles various YAML image formats in both templates and values.yaml:

```yaml
# In templates/ files:
image: localhost/my/repo
image: "localhost/my/repo"
image: 'localhost/my/repo'
image: localhost/my/repo:latest

# In values.yaml files:
repository: localhost/my/repo
repository: "localhost/my/repo"
repository: 'localhost/my/repo'
```

## Usage Examples

### Basic Usage

```yaml
apiVersion: tekton.dev/v1beta1
kind: TaskRun
metadata:
  name: build-helm-chart-oci-ta
spec:
  taskRef:
    name: build-helm-chart-oci-ta
  params:
  - name: IMAGE
    value: "quay.io/myorg/mychart:latest"
  - name: COMMIT_SHA
    value: "abc123"
  - name: SOURCE_ARTIFACT
    value: "oci://quay.io/myorg/source:abc123"
```

### With Image Substitution

```yaml
apiVersion: tekton.dev/v1beta1
kind: TaskRun
metadata:
  name: build-helm-chart-oci-ta-with-images
spec:
  taskRef:
    name: build-helm-chart-oci-ta
  params:
  - name: IMAGE
    value: "quay.io/myorg/mychart:latest"
  - name: COMMIT_SHA
    value: "abc123"
  - name: SOURCE_ARTIFACT
    value: "oci://quay.io/myorg/source:abc123"
  - name: IMAGE_MAPPINGS
    value: |
      [
        {
          "source": "localhost/myapp",
          "target": "quay.io/myorg/myapp:on-pr-{{revision}}"
        },
        {
          "source": "localhost/sidecar",
          "target": "quay.io/myorg/sidecar:on-pr-{{revision}}"
        }
      ]
```

### With Custom Values File

```yaml
apiVersion: tekton.dev/v1beta1
kind: TaskRun
metadata:
  name: build-helm-chart-oci-ta-with-custom-values
spec:
  taskRef:
    name: build-helm-chart-oci-ta
  params:
  - name: IMAGE
    value: "quay.io/myorg/mychart:latest"
  - name: COMMIT_SHA
    value: "abc123"
  - name: SOURCE_ARTIFACT
    value: "oci://quay.io/myorg/source:abc123"
  - name: VALUES_FILE
    value: "values-prod.yaml"
  - name: IMAGE_MAPPINGS
    value: |
      [
        {
          "source": "localhost/myapp",
          "target": "quay.io/myorg/myapp:on-pr-{{revision}}"
        }
      ]
```

### Chart Template and Values Example

**Before substitution:**

`templates/deployment.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
spec:
  template:
    spec:
      containers:
      - name: app
        image: localhost/myapp
      - name: sidecar
        image: localhost/sidecar
```

`values.yaml`:

```yaml
image:
  repository: localhost/myapp
  pullPolicy: IfNotPresent
  tag: ""

sidecar:
  image:
    repository: localhost/sidecar
    pullPolicy: IfNotPresent
    tag: ""
```

**After substitution** (assuming VERSION_SUFFIX="v1.2.3" and COMMIT_SHA="abc123"):

`templates/deployment.yaml`:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
spec:
  template:
    spec:
      containers:
      - name: app
        image: "quay.io/myorg/myapp:on-pr-eae88d147b23236dd3007ddfbf669356edf0028a"
      - name: sidecar
        image: "quay.io/myorg/sidecar:on-pr-eae88d147b23236dd3007ddfbf669356edf0028a"
```

`values.yaml`:
```yaml
image:
  repository: "quay.io/myorg/myapp"
  pullPolicy: IfNotPresent
  tag: "on-pr-eae88d147b23236dd3007ddfbf669356edf0028a"

sidecar:
  image:
    repository: "quay.io/myorg/sidecar"
    pullPolicy: IfNotPresent
    tag: "on-pr-eae88d147b23236dd3007ddfbf669356edf0028a"
```

## Version Calculation

The task calculates chart versions based on git tags:

1. **Tagged Version**: If a tag like `helm-1.2` exists, version becomes `1.2.0+<sha>`
2. **Distance from Tag**: If commits exist after tag, version becomes `1.2.<distance>+<sha>`
3. **Fallback**: If no matching tag exists, version becomes `0.1.<commit-count>+<sha>`

## Requirements

- Git repository with tags (for version calculation)
- Helm chart in the specified directory
- Access to the target OCI registry
- `yq` and `jq` tools (included in the container image)
- Trusted artifacts setup for source code access

## Notes

- Image substitution affects files in the `templates/` directory and the specified
  values file
- The task preserves YAML formatting and quotes target images consistently
- Source images are matched exactly (no partial matching)
- The task is idempotent - running it multiple times with the same mappings is safe
