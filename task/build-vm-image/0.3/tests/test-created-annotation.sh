#!/bin/bash
set -euo pipefail

# Run inside an isolated Buildah container. PACKAGING_SCRIPT is extracted from
# the production task by pre-apply-task-hook.sh, not reimplemented by this test.
: "${PACKAGING_SCRIPT:=/test-scripts/script-push.sh}"
test ! -e /output
test ! -L /output
TEST_DIR=$(mktemp -d)

verify_artifact() {
  local format=$1 source=$2 artifact_type=$3
  local case_dir output_index index_digest manifest_digest created before after
  case_dir=$(mktemp -d "${TEST_DIR}/${ARCHITECTURE}-${format}.XXXXXX")
  mkdir -p "${case_dir}/output/$(dirname "$source")"
  printf 'test disk content\n' > "${case_dir}/output/${source}"
  ln -s "${case_dir}/output" /output

  export OUTPUT_IMAGE="localhost/created-annotation:${ARCHITECTURE}-${format}-${RANDOM}"
  export IMAGE_TYPE="$format"
  before=$(date -u +%s)
  bash -euo pipefail "$PACKAGING_SCRIPT"
  after=$(date -u +%s)

  # Export the real index and child blobs. Checking the index descriptor alone
  # would incorrectly pass if --annotation replaced --artifact-annotation.
  buildah manifest push --all "$OUTPUT_IMAGE" "oci:${case_dir}/oci:artifact"
  output_index="${case_dir}/oci/index.json"
  index_digest=$(jq -er '.manifests[0].digest' "$output_index")
  output_index="${case_dir}/oci/blobs/sha256/${index_digest#sha256:}"
  manifest_digest=$(jq -er '.manifests[0].digest' "$output_index")
  jq -e '.manifests | length == 1' "$output_index"
  local manifest="${case_dir}/oci/blobs/sha256/${manifest_digest#sha256:}"
  jq -e --arg artifact_type "$artifact_type" \
    '.artifactType == $artifact_type and .config.mediaType == "application/vnd.oci.empty.v1+json"' "$manifest"
  local expected_path payload_digest
  case "$format" in
    raw|iso|vhd|vmdk|ova) expected_path="/output/${source}.gz" ;;
    pxe-tree) expected_path=/output/bootc-pxe-tree.tar.xz ;;
    *) expected_path="/output/${source}" ;;
  esac
  jq -e --arg filename "$(basename "$expected_path")" \
    '.layers | length == 1 and .[0].annotations["org.opencontainers.image.title"] == $filename' "$manifest"
  payload_digest=$(jq -er '.layers[0].digest' "$manifest")
  test "$payload_digest" = "sha256:$(sha256sum "$expected_path" | awk '{print $1}')"
  created=$(jq -er '.annotations["org.opencontainers.image.created"]' "$manifest")
  [[ "$created" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$ ]]
  local created_epoch
  created_epoch=$(date -u -d "$created" +%s)
  test "$created_epoch" -ge "$before"
  test "$created_epoch" -le "$after"
  unlink /output
  echo "PASS: ${ARCHITECTURE}/${format} created=${created}"
}

# Simulate each remote builder's architecture while using real Buildah for the
# packaging. Every output branch must annotate its child manifest with build time.
for ARCHITECTURE in x86_64 aarch64; do
  export ARCHITECTURE
  arch() { echo "$ARCHITECTURE"; }
  export -f arch
  while IFS='|' read -r format source artifact_type; do
    verify_artifact "$format" "$source" "$artifact_type"
  done <<'FORMATS'
qcow2|qcow2/disk.qcow2|application/vnd.diskimage.qcow2
raw|image/disk.raw|application/vnd.diskimage.raw.gzip
iso|bootiso/install.iso|application/vnd.diskimage.iso.gzip
vhd|vpc/disk.vhd|application/vnd.diskimage.vhd.gzip
gce|gce/image.tar.gz|application/vnd.diskimage.gce.tgz
vmdk|vmdk/disk.vmdk|application/vnd.diskimage.vmdk.gzip
ova|archive/image.ova|application/vnd.diskimage.ova.gzip
pxe-tar-xz|xz/pxe.tar.xz|application/vnd.diskimage.pxe.tar.xz
pxe-tree|bootc-pxe-tree/vmlinuz|application/vnd.diskimage.pxe.tar.xz
FORMATS
done
