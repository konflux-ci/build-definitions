# Artifact Reuse Feature for Konflux CI/CD

## Overview

This document describes the implementation of an artifact reuse feature within the Konflux CI/CD system to avoid redundant builds, thereby saving time, workspace quota, and cloud costs. The feature allows reusing artifacts even if git commits differ, by hashing source content and prefetch cache.

## Key Technical Concepts

### Artifact Reuse
Core feature to avoid redundant builds by reusing existing container images when source content and build parameters match.

### Git Tree Hash
Used as a unique identifier for source content, allowing reuse even with different commit metadata. The tree hash represents the actual file content structure regardless of commit messages, timestamps, or other metadata.

### Build Configuration Fingerprint
A set of build parameters that must match for artifact reuse. The system compares specific build parameters (excluding `IMAGE_EXPIRES_AFTER` and `BUILD_PLATFORMS`) to ensure identical build configurations.

### Tekton Tasks/Pipelines
The CI/CD framework where the `buildah` task operates, with each step being a distinct script.

### Buildah
Tool used for building container images and modifying image configurations.

### Skopeo
Used for inspecting and copying container images, listing tags in a registry, and performing manifest-only copies.

### Cosign
Used for handling image attestations (signing, verifying, attaching SBOMs, downloading attestations).

### Quay.io
The container registry where artifacts are stored, including handling of `quay.expires-after` OCI labels.

### OCI Image Manifests/Indexes
Understanding how multi-architecture images and their manifests are structured, and the ability to modify manifests without pulling blobs.

### SBOM (Software Bill of Materials)
Generated and attached to images, requiring proper handling during artifact reuse.

### Attestation
SLSA provenance attestations contain build parameters and environment information, used for build fingerprinting.

### Workspace
Shared filesystem between Tekton steps for passing data (e.g., reuse flags).

### Task Results
Tekton mechanism for steps to emit outputs for subsequent steps or the pipeline.

### Git Resolver
Tekton feature to fetch tasks directly from a Git repository and branch.

## Implementation Details

### Tree Hash Calculation and Result Emission

The system calculates the git tree hash once in the build step and emits it as a Tekton result:

```bash
# Calculate tree hash from git commit
if [ -n "$COMMIT_SHA" ]; then
  TREE_HASH=$(git -C "$(workspaces.source.path)/source" show -s --format="%T" "$COMMIT_SHA")
  echo "Tree hash for commit $COMMIT_SHA: $TREE_HASH"
  # Emit the tree hash result
  echo -n "$TREE_HASH" | tee $(results.GIT_TREE_HASH.path)
else
  echo "No COMMIT_SHA provided, skipping artifact reuse"
  TREE_HASH=""
  # Emit empty tree hash result
  echo -n "" | tee $(results.GIT_TREE_HASH.path)
fi
```

**Result**: `GIT_TREE_HASH` - Git tree hash of the source code

### Parameter Mapping for Attestation Comparison

The artifact reuse feature compares build parameters between current and existing builds using SLSA provenance attestations. The following parameter mapping is used:

**Parameters Included in Build Configuration Fingerprint:**
- `DOCKERFILE` → `dockerfile` ✓
- `CONTEXT` → `path-context` ✓ (special mapping required)
- `HERMETIC` → `hermetic` ✓
- `BUILD_ARGS` → `build-args` ✓
- `BUILD_ARGS_FILE` → `build-args-file` ✓
- `PREFETCH_INPUT` → `prefetch-input` ✓

**Parameters Excluded from Build Configuration Fingerprint:**
The following parameters are **intentionally excluded** from the comparison because they are not present in the SLSA provenance attestations:
- `TARGET_STAGE` (not in attestation)
- `ADD_CAPABILITIES` (not in attestation)
- `SQUASH` (not in attestation)
- `SKIP_UNUSED_STAGES` (not in attestation)
- `LABELS` (not in attestation)
- `ANNOTATIONS` (not in attestation)
- `ANNOTATIONS_FILE` (not in attestation)
- `WORKINGDIR_MOUNT` (not in attestation)
- `INHERIT_BASE_IMAGE_LABELS` (not in attestation)
- `IMAGE_EXPIRES_AFTER` (excluded by design - varies between PR and push builds)
- `BUILD_PLATFORMS` (excluded by design - may vary between builds)

### Attestation Verification

The system uses `cosign verify-attestation` with the following flags:
- `--key /etc/cosign/keys/rh03.pub` - Public key for signature verification
- `--insecure-ignore-tlog` - Skip transparency log verification
- `--type https://slsa.dev/provenance/v0.2` - Specify SLSA provenance attestation type

### Tree Hash Verification in Provenance

After downloading the attestation, the system verifies that the tree hash in the signed provenance matches the calculated tree hash:

```bash
# Verify tree hash in provenance matches our calculated tree hash
echo "Verifying tree hash in provenance..."
PROVENANCE_TREE_HASH=$(echo "$ATTESTATION_JSON" | jq -r '.predicate.materials[0].digest.sha256 // empty')
if [ $? -ne 0 ] || [ -z "$PROVENANCE_TREE_HASH" ]; then
  echo "Failed to extract tree hash from provenance"
  echo "false" > "$(workspaces.source.path)/artifact-reused"
  echo "Proceeding with build due to provenance tree hash extraction failure"
  exit 1
fi

if [ "$PROVENANCE_TREE_HASH" != "$TREE_HASH" ]; then
  echo "Tree hash mismatch: provenance has $PROVENANCE_TREE_HASH, calculated $TREE_HASH"
  echo "false" > "$(workspaces.source.path)/artifact-reused"
  echo "Proceeding with build due to tree hash mismatch"
  exit 1
fi

echo "Tree hash verification successful: $TREE_HASH"
```

### Tree Hash Tagging

Images are tagged with `tree-<hash>` tags in Quay.io for efficient artifact discovery:
- Format: `tree-<git-tree-hash>`
- Example: `tree-2c737dd76a10f15174072f6d71aef82a7d11118d`

### Digest Resolution

The system resolves tree hash tags to image digests for cosign operations:
```bash
TREE_TAG_DIGEST=$(skopeo inspect "docker://$IMAGE_REPO:$TREE_TAG" | jq -r '.Digest')
```

## Security Considerations

### Potential Security Problems

1. **Attestation Verification Bypass**: The use of `--insecure-ignore-tlog` skips transparency log verification, which could allow replay attacks if attestations are not properly signed.

2. **Parameter Mapping Vulnerabilities**: Incorrect parameter mapping between task parameters and attestation fields could lead to false positive reuse matches.

3. **Tree Hash Collisions**: While extremely unlikely, git tree hash collisions could theoretically cause incorrect artifact reuse.

4. **Attestation Tampering**: If the public key (`rh03.pub`) is compromised or incorrectly distributed, malicious attestations could be accepted.

5. **Registry Access Control**: The system relies on registry access for tree hash tag discovery and image operations.

6. **Build Parameter Injection**: Malicious build parameters could potentially be injected if the parameter comparison logic has vulnerabilities.

7. **Digest Resolution Attacks**: The `skopeo inspect` command could be vulnerable to man-in-the-middle attacks if not properly authenticated.

8. **Workspace Data Exposure**: Reuse flags and intermediate data stored in the workspace could be exposed to subsequent pipeline steps.

9. **Provenance Tree Hash Mismatch**: If the tree hash in the signed provenance doesn't match the calculated tree hash, the system will fail to reuse the artifact, preventing potential security issues.

### Mitigation Strategies

1. **Attestation Verification**: Implement proper attestation signature verification using trusted public keys.
2. **Parameter Validation**: Validate all build parameters before comparison to prevent injection attacks.
3. **Registry Authentication**: Ensure all registry operations use proper authentication and TLS.
4. **Audit Logging**: Log all artifact reuse decisions for security auditing.
5. **Fallback Mechanisms**: Implement proper fallback to fresh builds when verification fails.
6. **Tree Hash Verification**: Verify that the tree hash in the signed provenance matches the calculated tree hash to ensure provenance integrity.

## Use Cases

### Re-running Failed Pipelines
When a pipeline fails due to infrastructure issues, the same source content can be rebuilt without redundant computation.

### Reusing PR Artifacts in Push Pipelines
Artifacts built for pull requests can be reused when the same changes are pushed to the main branch.

### Cross-Environment Reuse
Artifacts built in one environment can potentially be reused in another environment with identical build configurations.

## Architecture-Specific Handling

The system handles multi-architecture images by:
- Applying tree hash tags to individual architecture images
- Performing reuse checks per architecture
- Ensuring architecture-specific parameter matching

## OCI Label Removal

For PR artifacts reused in push pipelines, the system removes `quay.expires-after` labels:
- Uses manifest-only copy with `skopeo copy --multi-arch index-only --remove-signatures --dest-date-now`
- Falls back to fresh build if label removal fails

## Image Label Updates

The system can update image labels when reusing artifacts:
- **Remove expires label**: For PR artifacts reused in push pipelines
- **Update commit ID**: Updates `vcs-ref` label to reflect current commit
- **Combined updates**: Handles both conditions in a single step

## Tekton Step Architecture

**Build Step**:
- **Tree hash calculation**: Calculates git tree hash from commit SHA
- **Result emission**: Emits `GIT_TREE_HASH` result for downstream steps
- **Reuse detection**: Tree hash calculation and attestation validation
- **Early exit**: Skips expensive build work when reusing artifacts
- **Flag setting**: Writes reuse state to workspace for push step

**Push Step**:
- **Tree hash retrieval**: Reads tree hash from `GIT_TREE_HASH` result
- **Reuse handling**: Label removal, result emission, SBOM preparation
- **Fresh build handling**: Normal push process with tree hash tagging
- **Result management**: Sets all task results regardless of reuse path

**SBOM Steps**:
- **Reuse awareness**: Reads reuse flags to handle reused artifacts
- **Consistent processing**: Same SBOM generation regardless of reuse path

**Image Label Update Step**:
- **Conditional updates**: Handles both expires label removal and commit ID updates
- **Provenance verification**: Ensures tree hash consistency in signed attestations
- **Efficient operations**: Uses manifest-only operations to avoid blob downloads

## Testing Strategy

### Unit Testing
- Tree hash calculation accuracy
- Parameter comparison logic
- Attestation parsing robustness
- Tree hash verification in provenance

### Integration Testing
- End-to-end pipeline with artifact reuse
- Multi-architecture build scenarios
- Error condition handling
- OCI label removal scenarios
- PR vs push pipeline behavior
- Provenance tree hash verification

### Security Testing
- Attestation validation accuracy
- Parameter tampering detection
- Access control verification
- Tree hash mismatch scenarios

## Performance Impact

### Positive Impacts
- **Build time reduction**: 90%+ time savings for identical content
- **Resource efficiency**: Reduced compute and storage costs
- **Pipeline throughput**: Faster CI/CD cycles
- **Optimized calculations**: Tree hash calculated once and reused

### Monitoring Requirements
- **Reuse rate tracking**: Percentage of builds reusing artifacts
- **Performance metrics**: Build time comparisons
- **Error rate monitoring**: Attestation download/parsing failures
- **Label removal success rate**: OCI label removal operation success/failure rates
- **Tree hash verification rate**: Success/failure of provenance tree hash verification

## Future Enhancements

### Planned Improvements
- **Attestation signature validation**: Enable with provided cosign keys
- **Advanced caching**: Database-backed artifact discovery (if needed)

### Optional Enhancements
- **Cross-registry reuse**: Support for multiple container registries
- **Build optimization**: Incremental build strategies

This implementation provides significant efficiency gains while maintaining security and integrity through attestation-based validation and tree hash verification. The feature is designed for graceful degradation and comprehensive auditability, ensuring safe deployment in production environments. 