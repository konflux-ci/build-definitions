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
  echo "[$(date --utc -Ins)] Reusing existing artifact - handling label removal and result emission"
  
  # Use the reused image reference from the result
  echo "Reused image reference: $REUSED_IMAGE_REF"
  
  # Handle label removal for PR artifacts reused in push pipelines
  if [ -n "${IMAGE_EXPIRES_AFTER:-}" ]; then
    echo "[$(date --utc -Ins)] Removing expires label from reused artifact"
    # Remove the expires label using manifest-only copy
    if ! skopeo copy --multi-arch index-only --remove-signatures \
      "docker://$REUSED_IMAGE_REF" "docker://$IMAGE"; then
      echo "ERROR: Failed to remove expires label from reused artifact"
      echo "ERROR: Cannot proceed with reused artifact that has expires label - this could result in production artifacts being garbage-collected"
      exit 1
    else
      echo "Successfully removed expires label"
      # Update the reused image reference to the new image
      REUSED_IMAGE_REF="$IMAGE"
    fi
  fi
  
  # Get the digest from the reused image (which may have been updated with label removal)
  # Use skopeo inspect to get the manifest digest directly
  REUSED_DIGEST=$(skopeo inspect "docker://$REUSED_IMAGE_REF" | jq -r '.Digest')
  echo "Final image digest: $REUSED_DIGEST"
  
  # Emit results for reused artifacts
  echo -n "$REUSED_DIGEST" | tee "$(results.IMAGE_DIGEST.path)"
  echo -n "$IMAGE" | tee "$(results.IMAGE_URL.path)"
  echo -n "$IMAGE@$REUSED_DIGEST" | tee "$(results.IMAGE_REF.path)"
  
  echo "[$(date --utc -Ins)] End push (reused artifact)"
  exit 0
fi

# Get tree hash from the result emitted by the build step
TREE_HASH=""
if [ -n "$COMMIT_SHA" ]; then
  TREE_HASH=$(cat "$(results.GIT_TREE_HASH.path)")
  echo "Tree hash from build step: $TREE_HASH"
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
    echo "[$(date --utc -Ins)] Adding tree hash tag: tree-$TREE_HASH"
    # Decode URL-encoded characters in IMAGE for proper tag creation
    DECODED_IMAGE="${IMAGE//%3A/:}"
    # Add the tree hash tag to the image
    if ! buildah tag "$IMAGE" "${DECODED_IMAGE%:*}:tree-$TREE_HASH"; then
      echo "Failed to add tree hash tag"
      exit 1
    fi
    # Push the tree hash tag
    if ! buildah push \
      --format="$push_format" \
      --retry "$retries" \
      --tls-verify="$TLSVERIFY" \
      "${DECODED_IMAGE%:*}:tree-$TREE_HASH" \
      "docker://${DECODED_IMAGE%:*}:tree-$TREE_HASH"; then
      echo "Failed to push tree hash tag after ${retries} tries"
      exit 1
    fi
    echo "Successfully added tree hash tag: tree-$TREE_HASH"
  fi
  tee "$(results.IMAGE_DIGEST.path)" < "$(workspaces.source.path)/image-digest"
  echo -n "$IMAGE" | tee "$(results.IMAGE_URL.path)"
  {
    echo -n "${IMAGE}@"
    cat "$(workspaces.source.path)/image-digest"
  } > "$(results.IMAGE_REF.path)"

echo
echo "[$(date --utc -Ins)] End push"

