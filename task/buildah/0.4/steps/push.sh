#!/bin/bash
set -e

echo "[$(date --utc -Ins)] Update CA trust"
ca_bundle=/mnt/trusted-ca/ca-bundle.crt
if [ -f "$ca_bundle" ]; then
  echo "INFO: Using mounted CA bundle: $ca_bundle"
  cp -vf "$ca_bundle" /etc/pki/ca-trust/source/anchors
  update-ca-trust
fi

# Check if we're reusing an artifact
REUSED_IMAGE_REF=$(cat "$(results.REUSED_IMAGE_REF.path)" 2>/dev/null || echo "")

if [ -n "$REUSED_IMAGE_REF" ]; then
  echo "[$(date --utc -Ins)] Reusing existing artifact..."
  echo "Reused image reference: $REUSED_IMAGE_REF"

  # Find the correct auth file to use for all remote operations
  AUTHFILE=""
  AUTH_FILES=(
    "/root/.docker/config.json"
    "${REGISTRY_AUTH_FILE:-}"
    "$HOME/.docker/config.json"
    "/var/run/secrets/kubernetes.io/serviceaccount/.dockerconfigjson"
    "${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/containers/auth.json"
    "/kaniko/.docker/config.json"
  )
  for f in "${AUTH_FILES[@]}"; do
      if [[ -n "$f" && -f "$f" ]]; then
          echo "Found auth file at $f"
          AUTHFILE="$f"
          break
      fi
  done

  if [[ -z "$AUTHFILE" ]]; then
      echo "WARNING: Could not find a valid registry authentication file. Continuing without explicit auth."
  fi



  # Handle label removal for PR artifacts reused in push pipelines
  should_remove_expires=false
  if skopeo inspect --authfile "$AUTHFILE" "docker://$REUSED_IMAGE_REF" | jq -e '.Labels["quay.expires-after"]' >/dev/null 2>&1; then
    echo "Image has expires label, checking if it should be removed."
    if [ "${REMOVE_EXPIRES_LABEL}" = "true" ] || [ "${EVENT_TYPE:-}" = "push" ] || [ "${EVENT_TYPE:-}" = "incoming" ]; then
      should_remove_expires=true
    fi
  fi

  # Determine if the vcs-ref label needs to be updated
  should_update_vcs_ref=false
  if [ -n "$COMMIT_SHA" ]; then
    CURRENT_VCS_REF=$(skopeo inspect --authfile "$AUTHFILE" "docker://$REUSED_IMAGE_REF" | jq -r '.Labels["vcs-ref"] // empty')
    if [ "$CURRENT_VCS_REF" != "$COMMIT_SHA" ]; then
      should_update_vcs_ref=true
    fi
  fi

  # Always run label-mod when we have a reused image to create tags
  NEED_CONFIG_UPDATE=true
  
  echo "DEBUG: should_remove_expires=$should_remove_expires"
  echo "DEBUG: should_update_vcs_ref=$should_update_vcs_ref"
  echo "DEBUG: NEED_CONFIG_UPDATE=$NEED_CONFIG_UPDATE"

  # Set the source reference for the copy operations later
  SOURCE_IMAGE_REF="$REUSED_IMAGE_REF"

  echo "[$(date --utc -Ins)] Using label-mod tool to create tags..."
  
  # Let label-mod find authentication in default locations
  echo "Using default authentication for label-mod"
  
  # Build the label-mod command with all operations
  LABEL_MOD_CMD="label-mod modify-labels $REUSED_IMAGE_REF"
  
  # Add remove operations if needed
  if [ "$should_remove_expires" = "true" ]; then
    LABEL_MOD_CMD="$LABEL_MOD_CMD --remove quay.expires-after"
    echo "Will remove expires label from config"
  fi
  
  # Add update operations if needed
  if [ "$should_update_vcs_ref" = "true" ]; then
    LABEL_MOD_CMD="$LABEL_MOD_CMD --update vcs-ref=$COMMIT_SHA"
    echo "Will update vcs-ref label to $COMMIT_SHA"
  fi
  
  # Add all the required tags (just the tag names, not full URLs)
  IMAGE_TAG="${IMAGE##*:}"
  LABEL_MOD_CMD="$LABEL_MOD_CMD --tag $IMAGE_TAG"
  LABEL_MOD_CMD="$LABEL_MOD_CMD --tag ${TASKRUN_NAME}"
  
  # Add tree hash tag if available
  TREE_HASH=""
  if [ -n "$COMMIT_SHA" ]; then
    TREE_HASH=$(cat "$(results.GIT_TREE_HASH.path)" 2>/dev/null || echo "")
    if [ -n "$TREE_HASH" ]; then
      # Use platform-specific tree hash tag if PLATFORM is available
      if [ -n "${PLATFORM:-}" ]; then
        # Sanitize platform string for use in Docker tags (replace problematic characters with '-')
        # Docker tags can only contain: a-z, A-Z, 0-9, _, ., -
        SANITIZED_PLATFORM="${PLATFORM//[^a-zA-Z0-9_.-]/-}"
        echo "Using platform-specific tree hash tag: tree-$TREE_HASH-$SANITIZED_PLATFORM"
        LABEL_MOD_CMD="$LABEL_MOD_CMD --tag tree-$TREE_HASH-$SANITIZED_PLATFORM"
      else
        LABEL_MOD_CMD="$LABEL_MOD_CMD --tag tree-$TREE_HASH"
        echo "Will add tree hash tag: tree-$TREE_HASH"
      fi
    fi
  fi
  
  # Run label-mod tool to update the image and create all tags
  echo "Running label-mod tool: $LABEL_MOD_CMD"
  if ! $LABEL_MOD_CMD; then
    echo "ERROR: Failed to update image labels using label-mod tool"
    exit 1
  fi
  
  echo "Successfully updated image config and created all tags using label-mod tool"
  # Update the source image reference to point to the primary image
  SOURCE_IMAGE_REF="$IMAGE"
  
  # Get the digest from the new image created by label-mod
  IMAGE_DIGEST=$(skopeo inspect --authfile "$AUTHFILE" "docker://$SOURCE_IMAGE_REF" | jq -r '.Digest')
  echo "Final image digest: $IMAGE_DIGEST"
  
  # Emit results for the new image
  echo -n "$IMAGE_DIGEST" | tee "$(results.IMAGE_DIGEST.path)"
  echo -n "$IMAGE" | tee "$(results.IMAGE_URL.path)"
  echo -n "$IMAGE@$IMAGE_DIGEST" | tee "$(results.IMAGE_REF.path)"
  
  echo "[$(date --utc -Ins)] End push (reused artifact)"
  exit 0
fi

# Get tree hash from the result emitted by the build step
TREE_HASH=""
if [ -n "$COMMIT_SHA" ]; then
  TREE_HASH=$(cat "$(results.GIT_TREE_HASH.path)" 2>/dev/null || echo "")
  if [ -n "$TREE_HASH" ]; then
    echo "Tree hash from build step: $TREE_HASH"
  else
    echo "No tree hash available (pre-build step may not have run)"
  fi
fi
echo "[$(date --utc -Ins)] Convert image"
# While we can build images with the desired format, we will simplify any local
# and remote build differences by just performing any necessary conversions at
# push time.
push_format=oci
if [ "${BUILDAH_FORMAT}" == "docker" ]; then
  push_format=docker
fi
echo "[$(date --utc -Ins)] Push image with unique tag"
retries=5
# Push to a unique tag based on the TaskRun name to avoid race conditions
echo "Pushing to ${IMAGE%:*}%3A${TASKRUN_NAME}"
if ! buildah push \
  --format="$push_format" \
  --retry "$retries" \
  --tls-verify="$TLSVERIFY" \
  "$IMAGE" \
  "docker://${IMAGE%:*}:${TASKRUN_NAME}"
    then
  echo "Failed to push sbom image to ${IMAGE%:*}:${TASKRUN_NAME}"
  exit 1
fi

echo "[$(date --utc -Ins)] Push image with git revision"
  # Push to a tag based on the git revision
  echo "Pushing to ${IMAGE}"
  if ! buildah push \
    --format="$push_format" \
    --retry "$retries" \
    --tls-verify="$TLSVERIFY" \
    --digestfile "$(workspaces.source.path)/image-digest" "$IMAGE" \
    "docker://$IMAGE"; then
    echo "Failed to push sbom image to $IMAGE after ${retries} tries"
    exit 1
  fi
  # Add tree hash tag if we have a tree hash
  if [ -n "$TREE_HASH" ]; then
    # Use platform-specific tree hash tag if PLATFORM is available
    if [ -n "${PLATFORM:-}" ]; then
      # Sanitize platform string for use in Docker tags (replace problematic characters with '-')
      # Docker tags can only contain: a-z, A-Z, 0-9, _, ., -
      SANITIZED_PLATFORM="${PLATFORM//[^a-zA-Z0-9_.-]/-}"
      TREE_TAG="tree-$TREE_HASH-$SANITIZED_PLATFORM"
      echo "[$(date --utc -Ins)] Adding platform-specific tree hash tag: $TREE_TAG"
    else
      TREE_TAG="tree-$TREE_HASH"
      echo "[$(date --utc -Ins)] Adding tree hash tag: $TREE_TAG"
    fi
    
    # Decode URL-encoded characters in IMAGE for proper tag creation
    DECODED_IMAGE="${IMAGE//%3A/:}"
    # Add the tree hash tag to the image
    if ! buildah tag "$IMAGE" "${DECODED_IMAGE%:*}:$TREE_TAG"; then
      echo "Failed to add tree hash tag"
      exit 1
    fi
    # Push the tree hash tag
    if ! buildah push \
      --format="$push_format" \
      --retry "$retries" \
      --tls-verify="$TLSVERIFY" \
      "${DECODED_IMAGE%:*}:$TREE_TAG" \
      "docker://${DECODED_IMAGE%:*}:$TREE_TAG"; then
      echo "Failed to push tree hash tag after ${retries} tries"
      exit 1
    fi
    echo "Successfully added tree hash tag: $TREE_TAG"
  fi
  tee "$(results.IMAGE_DIGEST.path)" < "$(workspaces.source.path)/image-digest"
  echo -n "$IMAGE" | tee "$(results.IMAGE_URL.path)"
  {
    echo -n "${IMAGE}@"
    cat "$(workspaces.source.path)/image-digest"
  } > "$(results.IMAGE_REF.path)"

echo
echo "[$(date --utc -Ins)] End push"

