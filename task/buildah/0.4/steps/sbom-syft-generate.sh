#!/bin/bash
echo "[$(date --utc -Ins)] Generate SBOM"

# Check if artifact is being reused
REUSED_IMAGE_REF=$(cat "$(results.REUSED_IMAGE_REF.path)" 2>/dev/null || echo "")
if [ -n "$REUSED_IMAGE_REF" ]; then
  echo "Artifact is being reused, skipping SBOM generation (will copy existing SBOM)"
  exit 0
fi

if [ "${SKIP_SBOM_GENERATION}" = "true" ]; then
  echo "Skipping SBOM generation"
  exit 0
fi
case $SBOM_TYPE in
  cyclonedx)
    syft_sbom_type=cyclonedx-json@1.5 ;;
  spdx)
    syft_sbom_type=spdx-json@2.3 ;;
  *)
    echo "Invalid SBOM type: $SBOM_TYPE. Valid: cyclonedx, spdx" >&2
    exit 1
    ;;
esac
echo "Running syft on the source directory"
syft dir:"$(workspaces.source.path)/$SOURCE_CODE_DIR/$CONTEXT" --output "$syft_sbom_type"="$(workspaces.source.path)/sbom-source.json"
echo "Running syft on the image"
syft oci-dir:"$(cat /shared/container_path)" --output "$syft_sbom_type"="$(workspaces.source.path)/sbom-image.json"
echo "[$(date --utc -Ins)] End sbom-syft-generate"

