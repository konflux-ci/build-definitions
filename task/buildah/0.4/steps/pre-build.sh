#!/bin/bash
set -euo pipefail

# Pre-build step: Calculate tree hash and check for reusable artifacts
# This step runs before the main build step to determine if we can reuse an existing artifact

echo "[$(date --utc -Ins)] Pre-build: Calculate tree hash and check for reusable artifacts"

# Check if artifact reuse is disabled
if [ "${REUSE_ARTIFACTS:-true}" = "false" ]; then
  echo "Artifact reuse is disabled (REUSE_ARTIFACTS=false), proceeding with fresh build"
  echo "false" > "$(workspaces.source.path)/artifact-reused"
  echo "" | tee "$(results.REUSED_IMAGE_REF.path)"
  echo "[$(date --utc -Ins)] Pre-build complete (artifact reuse disabled)"
  exit 0
fi

# Calculate tree hash from source code
if [ -n "${COMMIT_SHA:-}" ]; then
  echo "Calculating tree hash for commit ${COMMIT_SHA}..."
  TREE_HASH=$(git -C "$(workspaces.source.path)/source" show -s --format="%T" "${COMMIT_SHA}")
  echo "Tree hash for commit ${COMMIT_SHA}: ${TREE_HASH}"
else
  echo "No commit SHA provided, calculating tree hash from current source..."
  TREE_HASH=$(git -C "$(workspaces.source.path)/source" show -s --format="%T" HEAD)
  echo "Tree hash from current source: ${TREE_HASH}"
fi



# Store tree hash for use in subsequent steps
echo "${TREE_HASH}" > "$(workspaces.source.path)/tree-hash"

# Emit the GIT_TREE_HASH result
echo -n "${TREE_HASH}" | tee "$(results.GIT_TREE_HASH.path)"

# Check for reusable artifacts
echo "Checking for reusable artifacts with tree hash: ${TREE_HASH}"

# Parse exclusion list
EXCLUSION_PARAMS=()
if [ -n "${REUSE_COMPARISON_EXCLUSIONS:-}" ]; then
  while IFS= read -r line; do
    if [ -n "$line" ]; then
      # Remove leading dash and spaces from YAML list format
      cleaned_line="${line#- }"
      cleaned_line="${cleaned_line#-}"
      cleaned_line="${cleaned_line#"${cleaned_line%%[! ]*}"}"
      if [ -n "$cleaned_line" ]; then
        EXCLUSION_PARAMS+=("$cleaned_line")
      fi
    fi
  done <<< "$REUSE_COMPARISON_EXCLUSIONS"
fi

echo "Parameters to exclude from comparison: ${EXCLUSION_PARAMS[*]}"

# Check for existing tree hash tag
TREE_TAG="tree-${TREE_HASH}"
echo "Checking for tree tag: ${TREE_TAG} on ${IMAGE%:*} for architecture: $(uname -m)"

# Search for all candidates with this tree hash tag
TREE_TAG_CANDIDATES=()
while IFS= read -r tag; do
  if [ -n "$tag" ]; then
    TREE_TAG_CANDIDATES+=("$tag")
  fi
done < <(skopeo list-tags "docker://${IMAGE%:*}" 2>/dev/null | jq -r '.Tags[]' | grep "^${TREE_TAG}$" || true)

echo "Searching for all candidates with tree hash tag: ${TREE_TAG}"
echo "Found ${#TREE_TAG_CANDIDATES[@]} candidate(s) with tree hash tag: ${TREE_TAG}"

# If no candidates found, we need to build
  if [ ${#TREE_TAG_CANDIDATES[@]} -eq 0 ]; then
    echo "No existing tree hash tag found: ${TREE_TAG}"
    echo "false" > "$(workspaces.source.path)/artifact-reused"
    echo "Proceeding with build due to no existing tree hash tag"
    # Emit empty REUSED_IMAGE_REF to indicate no reuse
    echo "" | tee "$(results.REUSED_IMAGE_REF.path)"
else
  echo "Found ${#TREE_TAG_CANDIDATES[@]} candidate(s) with tree hash tag: ${TREE_TAG}"
  # If multiple candidates exist, find the newest one by checking build timestamps
  if [ ${#TREE_TAG_CANDIDATES[@]} -gt 1 ]; then
    echo "Multiple candidates found, selecting the newest one..."
    NEWEST_CANDIDATE=""
    NEWEST_TIMESTAMP=0
    for candidate in "${TREE_TAG_CANDIDATES[@]}"; do
      # Get the creation timestamp for this candidate
      TIMESTAMP=$(skopeo inspect "docker://${IMAGE%:*}:${candidate}" 2>/dev/null | jq -r '.Created // "0"' | date -f - +%s 2>/dev/null || echo "0")
      if [ "$TIMESTAMP" -gt "$NEWEST_TIMESTAMP" ]; then
        NEWEST_TIMESTAMP=$TIMESTAMP
        NEWEST_CANDIDATE=$candidate
      fi
    done
    if [ -n "$NEWEST_CANDIDATE" ]; then
      SELECTED_CANDIDATE=$NEWEST_CANDIDATE
      echo "Selected newest candidate: ${SELECTED_CANDIDATE}"
    else
      SELECTED_CANDIDATE=${TREE_TAG_CANDIDATES[0]}
      echo "Could not determine newest, using first candidate: ${SELECTED_CANDIDATE}"
    fi
  else
    SELECTED_CANDIDATE=${TREE_TAG_CANDIDATES[0]}
    echo "Single candidate found: ${SELECTED_CANDIDATE}"
  fi



  # Verify tree hash in provenance
  echo "Verifying tree hash in provenance..."
  ATTESTATION_JSON=$(cosign download attestation "${IMAGE%:*}:${SELECTED_CANDIDATE}" 2>/dev/null | jq -r '.payload | @base64d | fromjson' || echo "{}")
  
  if [ -z "$ATTESTATION_JSON" ] || [ "$ATTESTATION_JSON" = "{}" ]; then
          echo "No attestation found for ${IMAGE%:*}:${SELECTED_CANDIDATE}"
      echo "false" > "$(workspaces.source.path)/artifact-reused"
      echo "Proceeding with build due to no attestation"
      # Emit empty REUSED_IMAGE_REF to indicate no reuse
      echo "" | tee "$(results.REUSED_IMAGE_REF.path)"
  else
    PROVENANCE_TREE_HASH=$(echo "$ATTESTATION_JSON" | jq -r '.predicate.buildConfig.tasks[] | select(.results[]?.name == "GIT_TREE_HASH") | .results[] | select(.name == "GIT_TREE_HASH") | .value // empty')
    
          if [ -z "$PROVENANCE_TREE_HASH" ]; then
        echo "Failed to extract tree hash from provenance"
        echo "false" > "$(workspaces.source.path)/artifact-reused"
        echo "Proceeding with build due to provenance tree hash extraction failure"
        # Emit empty REUSED_IMAGE_REF to indicate no reuse
        echo "" | tee "$(results.REUSED_IMAGE_REF.path)"
    else
              if [ "$PROVENANCE_TREE_HASH" != "$TREE_HASH" ]; then
          echo "Tree hash mismatch: provenance has $PROVENANCE_TREE_HASH, calculated $TREE_HASH"
          echo "false" > "$(workspaces.source.path)/artifact-reused"
          echo "Proceeding with build due to tree hash mismatch"
          # Emit empty REUSED_IMAGE_REF to indicate no reuse
          echo "" | tee "$(results.REUSED_IMAGE_REF.path)"
      else
        echo "Tree hash verification successful: $TREE_HASH"
        # Extract build parameters from attestation
        EXISTING_PARAMS=$(echo "$ATTESTATION_JSON" | jq -r '.predicate.invocation.parameters')
        if [ -z "$EXISTING_PARAMS" ]; then
          echo "Failed to parse attestation parameters"
          echo "false" > "$(workspaces.source.path)/artifact-reused"
          echo "Proceeding with build due to attestation parsing failure"
          # Emit empty REUSED_IMAGE_REF to indicate no reuse
          echo "" | tee "$(results.REUSED_IMAGE_REF.path)"
        else
          echo "Extracted build parameters from existing attestation"
          # Compare current build parameters with existing ones
          CONFIG_MATCHES=true
          # Get all available parameters dynamically from environment variables
          # This will automatically include any new parameters that are added to the task
          ALL_PARAMS=()
          for env_var in $(env | grep -E '^[A-Z_]+=' | cut -d'=' -f1 | sort); do
            # Only include parameters that are likely to be task parameters
            # (exclude system environment variables and internal variables)
            if [[ "$env_var" =~ ^[A-Z_]+$ ]] && [[ ! "$env_var" =~ ^(PATH|HOME|USER|SHELL|PWD|HOSTNAME|TERM|LANG|LC_|SHLVL|LOGNAME|OLDPWD|_) ]]; then
              ALL_PARAMS+=("$env_var")
            fi
          done
          # Filter out excluded parameters
          COMPARISON_PARAMS=()
          for param in "${ALL_PARAMS[@]}"; do
            # Check if this parameter is in the exclusion list
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
          echo "Parameters to compare: ${COMPARISON_PARAMS[*]}"
          for param in "${COMPARISON_PARAMS[@]}"; do
            # Convert UPPER_SNAKE_CASE to kebab-case for attestation lookup
            param_kebab=$(echo "$param" | tr '[:upper:]' '[:lower:]' | sed 's/_/-/g')
            # Get current parameter value dynamically
            current_value=""
            # Special handling for CONTEXT parameter mapping
            if [ "$param" = "CONTEXT" ]; then
              param_kebab="path-context"
            fi
            # Use indirect parameter expansion to get the value dynamically
            # This will work for any parameter name without needing to update the case statement
            param_value="${!param:-}"
            if [ -n "$param_value" ]; then
              current_value="$param_value"
            else
              echo "Warning: Parameter $param not found in environment, treating as empty"
              current_value=""
            fi
            # Get existing parameter value from attestation
            # Only use exact matches to prevent parameter injection attacks
            existing_value=$(echo "$EXISTING_PARAMS" | jq -r --arg param "$param" --arg param_kebab "$param_kebab" '
              # Try exact match first
              if has($param) then .[$param]
              # Try kebab-case (only for known parameter mappings)
              elif has($param_kebab) then .[$param_kebab]
              # No case-insensitive matching for security
              else empty end
            ')
            
            # Handle default values for parameters that weren't provided
            # Check if this parameter exists in the attestation
            param_exists_in_attestation=$(echo "$EXISTING_PARAMS" | jq -r --arg param "$param" --arg param_kebab "$param_kebab" '
              # Try exact match first
              if has($param) then "true"
              # Try kebab-case (only for known parameter mappings)
              elif has($param_kebab) then "true"
              # No case-insensitive matching for security
              else "false" end
            ')
            
            # If parameter doesn't exist in attestation, it likely has a default value
            # and should be excluded from comparison (since it's not in the attestation)
            if [ "$param_exists_in_attestation" = "false" ]; then
              echo "Parameter $param not in attestation (likely has default value), skipping comparison"
              continue
            fi

            # If parameter exists in attestation, proceed with normal comparison
            # Compare values
            # Define array parameters that need special handling
            # This list can be easily updated when new array parameters are added
            if [[ "$param" =~ ^(BUILD_ARGS|LABELS|ANNOTATIONS)$ ]]; then
              # For array parameters, we need to sort and compare
              if [ "$current_value" != "$existing_value" ]; then
                echo "Parameter $param mismatch: current='$current_value' vs existing='$existing_value'"
                CONFIG_MATCHES=false
              fi
            else
              # For non-array parameters, direct comparison
              if [ "$current_value" != "$existing_value" ]; then
                echo "Parameter $param mismatch: current='$current_value' vs existing='$existing_value'"
                CONFIG_MATCHES=false
              fi
            fi
          done
          if [ "$CONFIG_MATCHES" = "true" ]; then
            echo "All build parameters match, reusing existing artifact"
            echo "true" > "$(workspaces.source.path)/artifact-reused"
            echo "${IMAGE%:*}:${SELECTED_CANDIDATE}" > "$(workspaces.source.path)/reused-image-ref"
            echo "${SELECTED_CANDIDATE}" > "$(workspaces.source.path)/reused-image-tag"
            # Store the reused image reference as a result for downstream steps
            echo -n "${IMAGE%:*}:${SELECTED_CANDIDATE}" | tee "$(results.REUSED_IMAGE_REF.path)"
            echo "Reusing existing artifact with tree hash: ${TREE_HASH}"
          else
            echo "Build parameters do not match, proceeding with build"
            echo "false" > "$(workspaces.source.path)/artifact-reused"
            # Emit empty REUSED_IMAGE_REF to indicate no reuse
            echo "" | tee "$(results.REUSED_IMAGE_REF.path)"
          fi
        fi
      fi
    fi
  fi
fi

echo "[$(date --utc -Ins)] Pre-build complete" 