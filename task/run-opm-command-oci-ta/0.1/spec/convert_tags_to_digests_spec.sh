#!/bin/env bash

set -o errexit
set -o pipefail
set -o nounset

# Check if shellspec is available
if ! command -v shellspec &> /dev/null; then
  echo "ERROR: shellspec is not installed or not in PATH." >&2
  echo "Install it with: curl -fsSL https://git.io/shellspec | sh" >&2
  echo "Or see: https://github.com/shellspec/shellspec#installation" >&2
  exit 1
fi

eval "$(shellspec - -c) exit 1"

task_path=run-opm-command-oci-ta.yaml

if [[ -f "../${task_path}" ]]; then
    task_path="../${task_path}"
fi

extract_script() {
  local script_dir
  script_dir="$(mktemp -d)"
  local script="${script_dir}/$1.sh"

  if ! yq -r ".spec.steps[] | select(.name == \"$1\").script" "${task_path}" > "${script}"; then
    echo "ERROR: Failed to extract script for step '$1' from ${task_path}" >&2
    exit 1
  fi

  # Verify script was extracted (not empty)
  if [[ ! -s "${script}" ]]; then
    echo "ERROR: Extracted script is empty. Step '$1' may not exist in ${task_path}" >&2
    exit 1
  fi

  # Fetch real utils.sh from konflux-test repository for accurate testing
  local utils_url="https://raw.githubusercontent.com/konflux-ci/konflux-test/main/test/utils.sh"
  local utils_file="${script_dir}/utils.sh"
  
  if ! curl -sSfL "${utils_url}" -o "${utils_file}" 2>/dev/null; then
    echo "ERROR: Failed to fetch utils.sh from ${utils_url}" >&2
    exit 1
  fi
  
  # Verify we got actual shell script content, not an error page
  if ! file "${utils_file}" | grep -qi "shell script"; then
    echo "ERROR: Downloaded file is not a valid shell script (might be an error page)" >&2
    echo "File type: $(file "${utils_file}")" >&2
    exit 1
  fi
  
  # Override load_utils to source the fetched utils.sh
  sed -i "s|load_utils() {|load_utils() { source ${utils_file}; return; # original: |g" "${script}"

  chmod +x "${script}"
  echo "${script}"
}

# array containing files/directories to remove on test exit
cleanup=()
trap 'rm -rf "${cleanup[@]}"' EXIT

# Extract the convert-image-tags-to-digests Step script so we can test it
convert_script="$(extract_script convert-image-tags-to-digests)"
cleanup+=("$(dirname "${convert_script}")")

testdir() {
    testdir="$(mktemp -d)" && cleanup+=("${testdir}") && cd "${testdir}"
    AfterEach "rm -rf \"\$testdir\""
}

# Helper to create a sample catalog JSON with images
create_catalog_with_images() {
    cat > catalog.json << 'EOF'
{
  "schema": "olm.bundle",
  "name": "test-operator.v1.0.0",
  "image": "registry.redhat.io/test/operator-bundle:v1.0.0",
  "relatedImages": [
    {
      "name": "operator",
      "image": "registry.redhat.io/test/operator:v1.0.0"
    },
    {
      "name": "already-digested",
      "image": "quay.io/test/image@sha256:abc123def456"
    }
  ]
}
EOF
}

# Helper to create catalog with only digest-based images
create_catalog_with_digests_only() {
    cat > catalog.json << 'EOF'
{
  "schema": "olm.bundle",
  "name": "test-operator.v1.0.0",
  "image": "quay.io/test/bundle@sha256:abc123",
  "relatedImages": [
    {
      "name": "operator",
      "image": "quay.io/test/operator@sha256:def456"
    }
  ]
}
EOF
}

Describe "convert-image-tags-to-digests"
    BeforeEach testdir

    export OPM_OUTPUT_PATH_PARAM="catalog.json"
    export CONVERT_TAGS_TO_DIGESTS_PARAM="true"

    It "handles missing catalog file gracefully"
        # Don't create catalog.json

        When call "${convert_script}"
        The status should eq 1
        The output should include "Converting image tags"
        The stderr should include "Catalog file"
        The stderr should include "not found"
    End

    It "handles empty catalog (no images)"
        cat > catalog.json << 'EOF'
{
  "schema": "olm.package",
  "name": "test-operator"
}
EOF

        When call "${convert_script}"
        The status should eq 0
        The output should include "No images found"
    End

    It "fails on empty image reference"
        cat > catalog.json << 'EOF'
{
  "schema": "olm.bundle",
  "image": ""
}
EOF

        When call "${convert_script}"
        The status should eq 1
        The output should include "Found 1 unique image"
        The stderr should include "empty image reference"
    End

    It "skips images that already have digests"
        create_catalog_with_digests_only

        # Mock skopeo - should not be called for digest images
        Mock skopeo
            echo "ERROR: skopeo should not be called for digest images" >&2
            exit 1
        End

        When call "${convert_script}"
        The status should eq 0
        The output should include "digest format"
        The output should include "No images needed conversion"
    End

    It "processes tagged images and calls skopeo"
        create_catalog_with_images

        # Mock skopeo to return digests
        Mock skopeo
            case "$*" in
                *"registry.redhat.io/test/operator-bundle:v1.0.0"*)
                    echo "sha256:bundledigest123"
                    ;;
                *"registry.redhat.io/test/operator:v1.0.0"*)
                    echo "sha256:operatordigest456"
                    ;;
                *)
                    echo "sha256:unknowndigest"
                    ;;
            esac
        End

        When call "${convert_script}"
        The status should eq 0
        The output should include "Found 3 unique image"
        The output should include "digest format"
        The output should include "Processing image:"
        The output should include "@sha256:bundledigest123"
        The output should include "@sha256:operatordigest456"
        The output should include "Successfully converted 2"
    End

    It "fails when skopeo cannot get digest"
        create_catalog_with_images

        # Mock skopeo - fail for bundle
        Mock skopeo
            echo "Error: transient network error" >&2
            exit 1
        End

        # Mock sleep to speed up tests
        Mock sleep
            :
        End

        When call "${convert_script}"
        The status should eq 1
        The output should include "Processing image:"
        The stderr should include "Failed to get digest"
    End

    It "fails when skopeo returns empty digest"
        create_catalog_with_images

        # Mock skopeo - return empty digest
        Mock skopeo
            echo ""
        End

        When call "${convert_script}"
        The status should eq 1
        The output should include "Processing image:"
        The stderr should include "Empty digest"
    End

    It "fails on images without tags"
        cat > catalog.json << 'EOF'
{
  "schema": "olm.bundle",
  "image": "registry.example.com/image-without-tag"
}
EOF

        When call "${convert_script}"
        The status should eq 1
        The output should include "Found 1 unique image"
        The stderr should include "has no tag"
    End
End
