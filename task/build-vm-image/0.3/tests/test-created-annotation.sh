#!/bin/bash
set -euo pipefail

# Run inside an isolated Buildah container. PACKAGING_SCRIPT is extracted from
# the production task by pre-apply-task-hook.sh, not reimplemented by this test.
: "${PACKAGING_SCRIPT:=/test-scripts/script-push.sh}"
test ! -e /output
test ! -L /output
TEST_DIR=$(mktemp -d)
SHARED_TIMESTAMP=2026-01-02T03:04:05Z

verify_artifact() {
  local format=$1 source=$2 artifact_type=$3 timestamp=$4
  local case_dir output_index index_digest manifest_digest created before after
  case_dir=$(mktemp -d "${TEST_DIR}/${ARCHITECTURE}-${format}.XXXXXX")
  mkdir -p "${case_dir}/output/$(dirname "$source")"
  printf 'test disk content\n' > "${case_dir}/output/${source}"
  ln -s "${case_dir}/output" /output

  export OUTPUT_IMAGE="localhost/created-annotation:${ARCHITECTURE}-${format}-${RANDOM}"
  export IMAGE_TYPE="$format" BUILD_TIMESTAMP="$timestamp"
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
  created=$(jq -er '.annotations["org.opencontainers.image.created"]' "$manifest")
  if [ -n "$timestamp" ]; then
    test "$created" = "$SHARED_TIMESTAMP"
  else
    [[ "$created" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$ ]]
    local created_epoch
    created_epoch=$(date -u -d "$created" +%s)
    test "$created_epoch" -ge "$before"
    test "$created_epoch" -le "$after"
  fi
  unlink /output
  echo "PASS: ${ARCHITECTURE}/${format} created=${created}"
}

# Simulate each remote builder's architecture while using real Buildah for the
# packaging. A shared timestamp must survive every output branch and matrix leg.
for ARCHITECTURE in x86_64 aarch64; do
  export ARCHITECTURE
  arch() { echo "$ARCHITECTURE"; }
  export -f arch
  while IFS='|' read -r format source artifact_type; do
    verify_artifact "$format" "$source" "$artifact_type" "$SHARED_TIMESTAMP"
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
  verify_artifact qcow2 qcow2/disk.qcow2 application/vnd.diskimage.qcow2 ""
done

# Invalid caller-provided dates must fail rather than publish unusable metadata.
export BUILD_TIMESTAMP=not-a-timestamp
if bash -euo pipefail "$PACKAGING_SCRIPT" > "${TEST_DIR}/invalid-date.log" 2>&1; then
  echo "ERROR: invalid BUILD_TIMESTAMP was accepted" >&2
  exit 1
fi
grep -q 'invalid date' "${TEST_DIR}/invalid-date.log"
echo "PASS: invalid timestamp rejected"
