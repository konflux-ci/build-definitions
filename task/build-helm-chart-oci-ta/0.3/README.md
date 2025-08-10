# Build Helm Chart OCI TA Task

This Tekton task packages and pushes a Helm chart to an OCI repository with support for
image substitution.

## Features

- **Chart Packaging**: Packages Helm charts with semver-compatible versioning
- **OCI Push**: Pushes packaged charts to OCI registries
- **Image Substitution**: Replaces source images with target images in chart templates
- **Git-based Versioning**: Uses git tags to determine chart versions
- **Trusted Artifacts**: Uses trusted artifacts for source code access

## Parameters

| Parameter | Description | Default | Required |
|-----------|-------------|---------|----------|
| `IMAGE` | Full image reference with tag (e.g., quay.io/redhat-user-workloads/konflux-vanguard-tenant/caching/squid:on-pr-{{revision}}) | - | Yes |
| `COMMIT_SHA` | Git commit SHA to build chart for | - | Yes |
| `SOURCE_ARTIFACT` | The Trusted Artifact URI pointing to the artifact with the application source code | - | Yes |
| `SOURCE_CODE_DIR` | Path relative to workingDir where code was pulled | `source` | No |
| `CHART_CONTEXT` | Path relative to SOURCE_CODE_DIR where chart is located | `dist/chart/` | No |
| `VERSION_SUFFIX` | Suffix to be added to the version string | `""` | No |
| `TAG_PREFIX` | Prefix for version tag matching | `helm-` | No |
| `IMAGE_MAPPINGS` | JSON array of image mappings for substitution. Substitutions occur in templates/ and all specified values files. | `[]` | No |
| `VALUES_FILES` | Array of values file names to process for image substitution (e.g., ["values.yaml", "values-prod.yaml"]) | `["values.yaml"]` | No |
| `CA_TRUST_CONFIG_MAP_NAME` | ConfigMap name for CA bundle | `trusted-ca` | No |
| `CA_TRUST_CONFIG_MAP_KEY` | ConfigMap key for CA bundle | `ca-bundle.crt` | No |

## Results

| Result | Description |
|--------|-------------|
| `IMAGE_DIGEST` | Digest of the OCI-Artifact just built |
| `IMAGE_URL` | OCI-Artifact repository and tag where the built OCI-Artifact was pushed |

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
   all specified values files, then replaces source images with target images (with
   standardized tags)

### Supported Image Formats

The substitution handles various YAML image formats in both templates and values files:

```yaml
# In templates/ files:
image: localhost/my/repo
image: "localhost/my/repo"
image: 'localhost/my/repo'
image: localhost/my/repo:latest

# In values files:
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

### With Custom Values Files

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
  - name: VALUES_FILES
    value:
      - "values.yaml"
      - "values-prod.yaml"
      - "values-dev.yaml"
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

- Image substitution affects files in the `templates/` directory and all specified
  values files
- The task preserves YAML formatting and quotes target images consistently
- Source images are matched exactly (no partial matching)
- The task is idempotent - running it multiple times with the same mappings is safe

