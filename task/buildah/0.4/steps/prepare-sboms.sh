#!/bin/bash
set -euo pipefail
echo "[$(date --utc -Ins)] Prepare SBOM"

# Check if artifact is being reused
REUSED_IMAGE_REF=$(cat "$(results.REUSED_IMAGE_REF.path)" 2>/dev/null || echo "")
if [ -n "$REUSED_IMAGE_REF" ]; then
  echo "Artifact is being reused, skipping SBOM preparation (will copy existing SBOM)"
  exit 0
fi

if [ "${SKIP_SBOM_GENERATION}" = "true" ]; then
  echo "Skipping SBOM generation"
  exit 0
fi
sboms_to_merge=(syft:sbom-source.json syft:sbom-image.json)
if [ -f "sbom-cachi2.json" ]; then
  sboms_to_merge+=(cachi2:sbom-cachi2.json)
fi
echo "Merging sboms: (${sboms_to_merge[*]}) => sbom.json"
python3 /scripts/merge_sboms.py "${sboms_to_merge[@]}" > sbom.json
echo "Adding image reference to sbom"
IMAGE_URL="$(cat "$(results.IMAGE_URL.path)")"
IMAGE_DIGEST="$(cat "$(results.IMAGE_DIGEST.path)")"
python3 /scripts/add_image_reference.py \
  --image-url "$IMAGE_URL" \
  --image-digest "$IMAGE_DIGEST" \
  --input-file sbom.json \
  --output-file /tmp/sbom.tmp.json
mv /tmp/sbom.tmp.json sbom.json
echo "Adding base images data to sbom.json"
python3 /scripts/base_images_sbom_script.py \
  --sbom=sbom.json \
  --parsed-dockerfile=/shared/parsed_dockerfile.json \
  --base-images-digests=/shared/base_images_digests
ADDITIONAL_BASE_IMAGES=()
while [[ $# -gt 0 ]]; do
  case $1 in
    --additional-base-images)
      shift
      while [[ $# -gt 0 && $1 != --* ]]
      do
        ADDITIONAL_BASE_IMAGES+=("$1")
        shift
      done
      ;;
    *)
      echo "unexpected argument: $1" >&2
      exit 2
      ;;
  esac
done
for ADDITIONAL_BASE_IMAGE in "${ADDITIONAL_BASE_IMAGES[@]}"; do
  IFS="@" read -ra BASE_IMAGE <<< "${ADDITIONAL_BASE_IMAGE}"
  python3 /scripts/add_image_reference.py \
    --builder-image \
    --image-url "${BASE_IMAGE[0]}" \
    --image-digest "${BASE_IMAGE[1]}" \
    --input-file sbom.json \
    --output-file /tmp/sbom.tmp.json
  mv /tmp/sbom.tmp.json sbom.json
done
echo "[$(date --utc -Ins)] End prepare-sboms"

