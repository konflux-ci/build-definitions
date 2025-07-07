#!/bin/bash
set -euo pipefail
echo "[$(date --utc -Ins)] Upload SBOM"

# Check if artifact is being reused
REUSED_IMAGE_REF=$(cat "$(results.REUSED_IMAGE_REF.path)" 2>/dev/null || echo "")
if [ -n "$REUSED_IMAGE_REF" ]; then
  echo "Artifact is being reused, copying SBOM from reused image to new image"
  
  # Set up CA trust
  ca_bundle=/mnt/trusted-ca/ca-bundle.crt
  if [ -f "$ca_bundle" ]; then
    echo "INFO: Using mounted CA bundle: $ca_bundle"
    cp -vf "$ca_bundle" /etc/pki/ca-trust/source/anchors
    update-ca-trust
  fi
  
  # Pre-select the correct credentials
  mkdir -p /tmp/auth && select-oci-auth "$(cat "$(results.IMAGE_REF.path)")" > /tmp/auth/config.json
  
  # Copy SBOM from reused artifact to new image tag
  NEW_IMAGE_REF=$(cat "$(results.IMAGE_REF.path)")
  echo "Copying SBOM from $REUSED_IMAGE_REF to $NEW_IMAGE_REF"
  
  # Download the existing SBOM from the reused image (which includes the digest)
  if DOCKER_CONFIG=/tmp/auth cosign download sbom "$REUSED_IMAGE_REF" > existing-sbom.json 2>/dev/null; then
    echo "Successfully downloaded SBOM from reused image"
    # Attach the existing SBOM to the new image tag
    if DOCKER_CONFIG=/tmp/auth cosign attach sbom --sbom existing-sbom.json "$NEW_IMAGE_REF" 2>/dev/null; then
      echo "Successfully attached SBOM to new image"
    else
      echo "Error: Failed to attach SBOM to new image"
      exit 1
    fi
  else
    echo "Error: No SBOM found on reused image $REUSED_IMAGE_REF"
    echo "Cannot reuse artifact without SBOM for security compliance"
    exit 1
  fi
  
  # Set SBOM blob URL result
  sbom_repo="${IMAGE%:*}"
  sbom_digest="$(sha256sum existing-sbom.json | cut -d' ' -f1)"
  echo -n "${sbom_repo}@sha256:${sbom_digest}" | tee "$(results.SBOM_BLOB_URL.path)"
  
  echo "[$(date --utc -Ins)] End upload-sbom (reused SBOM)"
  exit 0
fi

if [ "${SKIP_SBOM_GENERATION}" = "true" ]; then
  echo "Skipping SBOM generation"
  exit 0
fi
ca_bundle=/mnt/trusted-ca/ca-bundle.crt
if [ -f "$ca_bundle" ]; then
  echo "INFO: Using mounted CA bundle: $ca_bundle"
  cp -vf "$ca_bundle" /etc/pki/ca-trust/source/anchors
  update-ca-trust
fi
# Pre-select the correct credentials to work around cosign not supporting the containers-auth.json spec
mkdir -p /tmp/auth && select-oci-auth "$(cat "$(results.IMAGE_REF.path)")" > /tmp/auth/config.json
DOCKER_CONFIG=/tmp/auth cosign attach sbom --sbom sbom.json --type "$SBOM_TYPE" "$(cat "$(results.IMAGE_REF.path)")"
# Remove tag from IMAGE while allowing registry to contain a port number.
sbom_repo="${IMAGE%:*}"
sbom_digest="$(sha256sum sbom.json | cut -d' ' -f1)"
# The SBOM_BLOB_URL is created by `cosign attach sbom`.
echo -n "${sbom_repo}@sha256:${sbom_digest}" | tee "$(results.SBOM_BLOB_URL.path)"
echo
echo "[$(date --utc -Ins)] End upload-sbom"

