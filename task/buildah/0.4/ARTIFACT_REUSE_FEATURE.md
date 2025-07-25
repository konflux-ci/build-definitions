# Artifact Reuse Feature for Konflux CI/CD

## Overview

This document describes the implementation of an artifact reuse feature within the Konflux CI/CD system to avoid redundant builds, thereby saving time, workspace quota, and cloud costs. The feature allows reusing artifacts even if git commits differ, by hashing source content and prefetch cache.

## Key Technical Concepts

### Artifact Reuse
Core feature to avoid redundant builds by reusing existing container images when source content and build parameters match.

### Git Tree Hash
Used as a unique identifier for source content, allowing reuse even with different commit metadata. The tree hash represents the actual file content structure regardless of commit messages, timestamps, or other metadata.

### Build Configuration Fingerprint
A set of build parameters that must match for artifact reuse. The system compares all **task parameters** (not pipeline parameters) except those explicitly excluded via the `REUSE_COMPARISON_EXCLUSIONS` parameter to ensure identical build configurations.

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

Equivalent results should be emitted for every and every task in the pipeline.
The prevents downstream tasks from breaking when artifacts are resued.

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

### Dynamic Parameter Comparison

The artifact reuse feature uses an exclusion-based approach for parameter comparison. All **task parameters** (not pipeline parameters) are automatically included in the build configuration fingerprint unless explicitly excluded via the `REUSE_COMPARISON_EXCLUSIONS` parameter.

#### Parameter Discovery and Comparison

The system dynamically discovers all available **task parameters** from environment variables and filters out excluded ones:

```bash
# Get all available task parameters dynamically from environment variables
# This will automatically include any new task parameters that are added to the task
ALL_PARAMS=()
for env_var in $(env | grep -E '^[A-Z_]+=' | cut -d'=' -f1 | sort); do
  # Only include parameters that are likely to be task parameters
  # (exclude system environment variables and internal variables)
  if [[ "$env_var" =~ ^[A-Z_]+$ ]] && [[ ! "$env_var" =~ ^(PATH|HOME|USER|SHELL|PWD|HOSTNAME|TERM|LANG|LC_|SHLVL|LOGNAME|OLDPWD|_) ]]; then
    ALL_PARAMS+=("$env_var")
  fi
done

# Filter out excluded task parameters
COMPARISON_PARAMS=()
for param in "${ALL_PARAMS[@]}"; do
  # Check if this task parameter is in the exclusion list
  excluded=false
  for excluded_param in "${EXCLUSION_PARAMS[@]}"; do
    if [ "$param" = "$excluded_param" ]; then
      excluded=true
      break
    fi
  done
  
  if [ "$excluded" = "false" ]; then
    COMPARISON_PARAMS+=("$param")
  fi
done
```

#### Default Exclusion List

The following **task parameters** are excluded by default from the build configuration fingerprint:

```yaml
REUSE_COMPARISON_EXCLUSIONS:
  - IMAGE_EXPIRES_AFTER
  - COMMIT_SHA

```

#### Parameter Mapping for Attestation Comparison

The system dynamically maps **task parameters** to attestation fields using kebab-case conversion:

```bash
# Convert UPPER_SNAKE_CASE to kebab-case for attestation lookup
param_kebab=$(echo "$param" | tr '[:upper:]' '[:lower:]' | sed 's/_/-/g')

# Special handling for CONTEXT parameter mapping
if [ "$param" = "CONTEXT" ]; then
  param_kebab="path-context"
fi
```

**Parameters Excluded from Build Configuration Fingerprint:**
The following **task parameters** are **intentionally excluded** from the comparison:
- `IMAGE_EXPIRES_AFTER` (varies between PR and push builds)
- `COMMIT_SHA` (metadata, not build configuration)


#### Dynamic Parameter Value Retrieval

The system uses indirect parameter expansion to dynamically retrieve **task parameter** values:

```bash
# Use indirect parameter expansion to get the value dynamically
# This will work for any parameter name without needing to update the case statement
param_value="${!param:-}"
if [ -n "$param_value" ]; then
  current_value="$param_value"
else
  echo "Warning: Parameter $param not found in environment, treating as empty"
  current_value=""
fi
```

#### Array Parameter Handling

Special handling is provided for array **task parameters** to compare empty strings with empty arrays:

```bash
# Define array parameters that need special handling
# This list can be easily updated when new array parameters are added
ARRAY_PARAMS=("BUILD_ARGS" "LABELS" "ANNOTATIONS" "ADDITIONAL_BASE_IMAGES")

# Check if current parameter is an array parameter
is_array_param=false
for array_param in "${ARRAY_PARAMS[@]}"; do
  if [ "$param" = "$array_param" ]; then
    is_array_param=true
    break
  fi
done

if [ "$is_array_param" = "true" ]; then
  # Special handling for array parameters - compare empty string with empty array
  if [ "$current_value" = "" ] && [ "$existing_value" = "[]" ]; then
    echo "Parameter $param matches: '$current_value' (empty) vs '$existing_value' (empty array)"
  elif [ "$current_value" = "$existing_value" ]; then
    echo "Parameter $param matches: '$current_value'"
  else
    echo "Parameter mismatch for $param: current='$current_value' vs existing='$existing_value'"
    CONFIG_MATCHES=false
    break
  fi
else
  # Regular comparison for other parameters
  if [ "$current_value" != "$existing_value" ]; then
    echo "Parameter mismatch for $param: current='$current_value' vs existing='$existing_value'"
    CONFIG_MATCHES=false
    break
  else
    echo "Parameter $param matches: '$current_value'"
  fi
fi
```

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
PROVENANCE_TREE_HASH=$(echo "$ATTESTATION_JSON" | jq -r '.predicate.buildConfig.tasks[] | select(.name == "build-container") | .results[] | select(.name == "GIT_TREE_HASH") | .value // empty')
if [ -z "$PROVENANCE_TREE_HASH" ]; then
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

**Important Security Note**: The tree hash tag is only used as a **candidate identifier** for potential artifact reuse. The system does **not** blindly trust this tag. Instead, it performs comprehensive security verification by:

1. **Downloading and verifying attestations** from the candidate image
2. **Validating cryptographic signatures** using trusted public keys
3. **Extracting and comparing tree hashes** from the signed provenance
4. **Verifying parameter consistency** between current and attested builds

This multi-layered verification prevents potential attack vectors where malicious actors could create fake tree hash tags.

### Digest Resolution

The system resolves tree hash tags to image digests for cosign operations:
```bash
TREE_TAG_DIGEST=$(skopeo inspect "docker://$IMAGE_REPO:$TREE_TAG" | jq -r '.Digest')
```

### Security Verification Process

After discovering a candidate artifact via tree hash tag, the system performs the following security verification steps:

#### 1. Attestation Download and Verification
```bash
# Validate attestation signature using cosign with digest
if ! cosign verify-attestation --key /etc/cosign/keys/rh03.pub --insecure-ignore-tlog --type https://slsa.dev/provenance/v0.2 "$IMAGE_REPO@$TREE_TAG_DIGEST" >/dev/null 2>&1; then
  echo "Failed to verify attestation signature"
  echo "false" > "$(workspaces.source.path)/artifact-reused"
  echo "Proceeding with build due to attestation verification failure"
  exit 1
fi
```

#### 2. Provenance Extraction and Tree Hash Verification
```bash
# Use the digest for attestation download
ATTESTATION_JSON=$(cosign download attestation "$IMAGE_REPO@$TREE_TAG_DIGEST" 2>/dev/null | jq -r '.payload | @base64d | fromjson')
if [ -z "$ATTESTATION_JSON" ]; then
  echo "Failed to download attestation for $IMAGE_REPO@$TREE_TAG"
  echo "false" > "$(workspaces.source.path)/artifact-reused"
  echo "Proceeding with build due to attestation download failure"
  exit 1
fi

# Verify tree hash in provenance matches our calculated tree hash
echo "Verifying tree hash in provenance..."
PROVENANCE_TREE_HASH=$(echo "$ATTESTATION_JSON" | jq -r '.predicate.buildConfig.tasks[] | select(.name == "build-container") | .results[] | select(.name == "GIT_TREE_HASH") | .value // empty')
if [ -z "$PROVENANCE_TREE_HASH" ]; then
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

#### 3. Build Parameter Verification
After tree hash verification, the system extracts and compares build parameters from the signed attestation to ensure identical build configurations.

This multi-step verification process ensures that:
- **Cryptographic signatures** validate the authenticity of the attestation
- **Tree hash consistency** confirms the source content matches
- **Parameter comparison** ensures build configurations are identical
- **Graceful degradation** falls back to fresh builds if any verification step fails

## Security Considerations

### Security Design Philosophy

The artifact reuse feature is designed with a **defense-in-depth** approach that does not trust any single identifier or tag. Instead, it implements a multi-layered verification process that validates:

1. **Cryptographic signatures** on attestations
2. **Tree hash consistency** between calculated and attested values
3. **Build parameter matching** from signed provenance
4. **Graceful degradation** when verification fails

This approach prevents various attack vectors while maintaining the efficiency benefits of artifact reuse.

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

10. **Dynamic Parameter Discovery**: The automatic discovery of parameters from environment variables could potentially include sensitive data if not properly filtered.

11. **Fake Tree Hash Tags**: Malicious actors could potentially create fake tree hash tags to trigger reuse attempts.

### Mitigation Strategies

1. **Multi-Layered Verification**: The system does not trust tree hash tags alone but performs comprehensive verification including attestation signatures, tree hash consistency, and parameter matching.

2. **Attestation Verification**: Implement proper attestation signature verification using trusted public keys.

3. **Parameter Validation**: Validate all build parameters before comparison to prevent injection attacks.

4. **Registry Authentication**: Ensure all registry operations use proper authentication and TLS.

5. **Audit Logging**: Log all artifact reuse decisions for security auditing.

6. **Fallback Mechanisms**: Implement proper fallback to fresh builds when verification fails.

7. **Tree Hash Verification**: Verify that the tree hash in the signed provenance matches the calculated tree hash to ensure provenance integrity.

8. **Environment Variable Filtering**: Carefully filter environment variables to exclude system and sensitive data.

9. **Exclusion List Management**: Maintain a comprehensive exclusion list to prevent sensitive parameters from being compared.

10. **Graceful Degradation**: Any verification failure results in a fresh build rather than potentially insecure reuse.

### Security Verification Flow

The system implements the following security verification flow:

```
Tree Hash Tag Discovery
         ↓
   Digest Resolution
         ↓
Attestation Download
         ↓
Signature Verification ← FAIL → Fresh Build
         ↓
Tree Hash Extraction
         ↓
Tree Hash Comparison ← FAIL → Fresh Build
         ↓
Parameter Extraction
         ↓
Parameter Comparison ← FAIL → Fresh Build
         ↓
    Artifact Reuse
```

This flow ensures that **every step** must succeed for artifact reuse to occur, providing multiple layers of security validation.

## Use Cases

### Re-running Failed Pipelines
When a pipeline fails due to infrastructure issues, the same source content can be rebuilt without redundant computation.

### Reusing PR Artifacts in Push Pipelines
Artifacts built for pull requests can be reused when the same changes are pushed to the main branch.

### Cross-Environment Reuse
Artifacts built in one environment can potentially be reused in another environment with identical build configurations.

### Future-Proof Parameter Handling
New **task parameters** added to the task are automatically included in comparison unless explicitly excluded, making the system more robust and maintainable.

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
- **Dynamic parameter discovery**: Automatically discovers all available **task parameters**
- **Exclusion filtering**: Filters out **task parameters** in the exclusion list
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
- Dynamic **task parameter** discovery and filtering
- **Task parameter** comparison logic
- Attestation parsing robustness
- Tree hash verification in provenance
- Array **task parameter** handling

### Integration Testing
- End-to-end pipeline with artifact reuse
- Multi-architecture build scenarios
- Error condition handling
- OCI label removal scenarios
- PR vs push pipeline behavior
- Provenance tree hash verification
- New **task parameter** addition scenarios

### Security Testing
- Attestation validation accuracy
- **Task parameter** tampering detection
- Access control verification
- Tree hash mismatch scenarios
- Environment variable filtering
- Exclusion list effectiveness

## Performance Impact

### Positive Impacts
- **Build time reduction**: 90%+ time savings for identical content
- **Resource efficiency**: Reduced compute and storage costs
- **Pipeline throughput**: Faster CI/CD cycles
- **Optimized calculations**: Tree hash calculated once and reused
- **Future-proof design**: Automatic handling of new parameters

### Monitoring Requirements
- **Reuse rate tracking**: Percentage of builds reusing artifacts
- **Performance metrics**: Build time comparisons
- **Error rate monitoring**: Attestation download/parsing failures
- **Label removal success rate**: OCI label removal operation success/failure rates
- **Tree hash verification rate**: Success/failure of provenance tree hash verification
- **Parameter discovery rate**: Number of **task parameters** discovered vs excluded
- **Dynamic comparison success rate**: Success/failure of dynamic **task parameter** comparison

## Future Enhancements

### Planned Improvements
- **Attestation signature validation**: Enable with provided cosign keys
- **Advanced caching**: Database-backed artifact discovery (if needed)
- **Configurable exclusion lists**: Allow runtime configuration of exclusion lists for **task parameters**
- **Parameter importance weighting**: Assign different weights to **task parameters** based on their impact on build output

### Optional Enhancements
- **Cross-registry reuse**: Support for multiple container registries
- **Build optimization**: Incremental build strategies
- **Parameter dependency tracking**: Track which **task parameters** affect which build stages
- **Smart exclusion suggestions**: Automatically suggest **task parameters** to exclude based on usage patterns

This implementation provides significant efficiency gains while maintaining security and integrity through attestation-based validation and tree hash verification. The dynamic **task parameter** handling makes the system more robust and future-proof, automatically adapting to new **task parameters** while maintaining strict control over what gets compared. The feature is designed for graceful degradation and comprehensive auditability, ensuring safe deployment in production environments. 