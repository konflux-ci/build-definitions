# build-macos-native-remote

## Description

Builds native macOS applications on remote macOS instances provisioned by the multi-platform-controller (MPC).

This task is designed for building desktop applications (e.g., Electron apps, Swift apps) that require native macOS build environments. It handles:

- Remote macOS instance provisioning via MPC
- Source code synchronization to remote instance
- Native build execution (Node.js, pnpm, Python, etc.)
- Optional code signing and notarization
- Artifact synchronization back to workspace

## Parameters

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `OUTPUT_NAME` | string | - | **Required.** Name for the output artifact (e.g., "podman-desktop-1.2.3") |
| `PLATFORM` | string | - | **Required.** Target platform (e.g., "macos/arm64", "macos/amd64") |
| `COMMIT_SHA` | string | "" | Git commit SHA for versioning and metadata |
| `SOURCE_URL` | string | "" | Source repository URL for metadata |
| `BUILD_COMMAND` | string | "pnpm compile:next" | Build command to execute on the remote macOS instance |
| `NODE_VERSION` | string | "22" | Node.js version to use (for documentation; tools must be pre-installed) |
| `ENABLE_CODE_SIGNING` | string | "false" | Enable macOS code signing (requires signing secrets) |
| `CODE_SIGNING_SECRET` | string | "macos-signing-secret" | Name of secret containing code signing credentials |
| `CONTEXT` | string | "." | Path to context directory (relative to workspace source) |
| `BUILD_ENV_VARS` | string | "" | Additional environment variables (KEY=VALUE format, one per line) |
| `ARTIFACT_PATTERN` | string | "dist/*.dmg" | Artifact file pattern to sync back from remote instance |

## Results

| Name | Description |
|------|-------------|
| `ARTIFACT_PATH` | Path to the built artifact in the workspace (relative) |
| `ARTIFACT_SHA256` | SHA256 checksum of the built artifact |
| `APP_VERSION` | Application version extracted from package.json (if available) |

## Workspaces

| Name | Description |
|------|-------------|
| `source` | Workspace containing the source code to build |

## Volumes/Secrets

### Required Secrets

- **`multi-platform-ssh-$(context.taskRun.name)`**: Auto-created by multi-platform-controller
  - Contains SSH credentials for accessing the remote macOS instance
  - Created automatically when MPC provisions an instance

### Optional Secrets (Code Signing)

When `ENABLE_CODE_SIGNING=true`, the task expects a secret with the following keys:

- **`CSC_LINK`**: Base64-encoded code signing certificate (.p12)
- **`CSC_KEY_PASSWORD`**: Password for the certificate
- **`APPLE_ID`**: Apple ID for notarization
- **`APPLE_APP_SPECIFIC_PASSWORD`**: App-specific password for Apple ID
- **`APPLE_TEAM_ID`**: Apple Developer Team ID

Secret name is specified via the `CODE_SIGNING_SECRET` parameter (default: `macos-signing-secret`).

## Prerequisites

### Remote macOS Instance Requirements

The remote macOS instances must have the following pre-installed:

- **Node.js** (version matching `NODE_VERSION` parameter)
- **pnpm** (package manager)
- **Python** (if required by the build)
- **Xcode Command Line Tools** (for native compilation)
- **rsync** (for file synchronization)

### Multi-Platform-Controller Setup

This task requires the multi-platform-controller to be running in the cluster. The controller:

1. Watches for TaskRuns with a `PLATFORM` parameter
2. Provisions appropriate macOS instances (AWS EC2, fixed pools, etc.)
3. Creates SSH credentials secret for the task
4. Handles instance cleanup after build completion

For more information, see: https://github.com/konflux-ci/multi-platform-controller

## Usage Examples

### Basic Build (No Code Signing)

```yaml
apiVersion: tekton.dev/v1
kind: TaskRun
metadata:
  name: build-podman-desktop
spec:
  taskRef:
    name: build-macos-native-remote
  params:
    - name: OUTPUT_NAME
      value: "podman-desktop-1.2.3"
    - name: PLATFORM
      value: "macos/arm64"
    - name: COMMIT_SHA
      value: "abc123def456"
    - name: SOURCE_URL
      value: "https://github.com/podman-desktop/podman-desktop"
    - name: BUILD_COMMAND
      value: "pnpm compile:next"
  workspaces:
    - name: source
      persistentVolumeClaim:
        claimName: source-pvc
```

### Build with Code Signing

```yaml
apiVersion: tekton.dev/v1
kind: TaskRun
metadata:
  name: build-podman-desktop-signed
spec:
  taskRef:
    name: build-macos-native-remote
  params:
    - name: OUTPUT_NAME
      value: "podman-desktop-1.2.3"
    - name: PLATFORM
      value: "macos/arm64"
    - name: ENABLE_CODE_SIGNING
      value: "true"
    - name: CODE_SIGNING_SECRET
      value: "my-macos-signing-creds"
    - name: BUILD_COMMAND
      value: "pnpm compile:next"
  workspaces:
    - name: source
      persistentVolumeClaim:
        claimName: source-pvc
```

### Build with Custom Environment Variables

```yaml
apiVersion: tekton.dev/v1
kind: TaskRun
metadata:
  name: build-with-env
spec:
  taskRef:
    name: build-macos-native-remote
  params:
    - name: OUTPUT_NAME
      value: "my-app-2.0.0"
    - name: PLATFORM
      value: "macos/amd64"
    - name: BUILD_ENV_VARS
      value: |
        CUSTOM_VAR=value1
        ANOTHER_VAR=value2
        DEBUG=true
    - name: ARTIFACT_PATTERN
      value: "out/make/**/*.dmg"
  workspaces:
    - name: source
      persistentVolumeClaim:
        claimName: source-pvc
```

## How It Works

1. **Connection Setup**: Task retrieves SSH credentials from the MPC-created secret
2. **Remote Preparation**: Creates build directories on the remote macOS instance
3. **Code Sync**: Uses `rsync` to transfer source code to the remote instance
4. **Environment Setup**: If code signing is enabled, syncs signing credentials
5. **Build Execution**: Runs the build command on the remote instance
6. **Artifact Collection**: Finds artifacts matching the pattern and syncs them back
7. **Checksum Calculation**: Computes SHA256 checksums for artifacts
8. **Results**: Returns artifact paths and metadata

## Differences from buildah-remote

While this task is inspired by `buildah-remote`, key differences include:

- **No container builds**: Builds native macOS applications, not container images
- **No SBOM generation**: Focused on application builds, not container security
- **No registry push**: Returns artifacts to workspace instead of pushing to registry
- **Pre-installed tools**: Assumes build tools (Node.js, pnpm) are pre-installed on instances
- **Code signing**: Supports macOS-specific code signing and notarization

## Troubleshooting

### "No artifacts found matching pattern"

- Check that `ARTIFACT_PATTERN` matches the actual build output location
- Verify the build command completed successfully
- Check the build logs for the actual output directory

### "node is not installed on the remote macOS instance"

- Ensure the macOS instance has Node.js pre-installed
- Verify the instance configuration in multi-platform-controller

### Code signing fails

- Verify all signing secrets are properly configured
- Check that `CSC_LINK` is base64-encoded
- Ensure `APPLE_ID` and `APPLE_APP_SPECIFIC_PASSWORD` are valid
- Verify the certificate is not expired

### SSH connection timeout

- Check multi-platform-controller logs for provisioning issues
- Verify network connectivity between cluster and macOS instances
- Check AWS security groups allow SSH traffic

## Version History

### 0.1.0 (Initial Release)

- Initial implementation for macOS native builds
- Support for remote build execution via multi-platform-controller
- Optional code signing support
- Artifact synchronization back to workspace
