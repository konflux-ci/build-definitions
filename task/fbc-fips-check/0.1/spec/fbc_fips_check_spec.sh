#!/bin/env bash

set -o errexit
set -o pipefail
set -o nounset

eval "$(shellspec - -c) exit 1"

task_path=fbc-fips-check.yaml
if [[ -f "../${task_path}" ]]; then
    task_path="../${task_path}"
fi

cleanup=()
trap 'rm -rf "${cleanup[@]}"' EXIT

tekton_home=$(mktemp -d) && cleanup+=("${tekton_home}")
results_dir=$(mktemp -d) && cleanup+=("${results_dir}")
workspace_dir=$(mktemp -d) && cleanup+=("${workspace_dir}")

export FBC_TEST_BUNDLE_JSON="${tekton_home}/bundle_mock.json"

mock_utils=$(mktemp --tmpdir mock_utils_XXXXXXXXXX.sh) && cleanup+=("${mock_utils}")
cat > "${mock_utils}" << 'MOCK_UTILS_EOF'
get_image_manifests() { echo '{"amd64": "sha256:abc123"}'; }
get_ocp_version_from_fbc_fragment() { echo "v4.16"; }
get_target_fbc_catalog_image() { echo "registry.redhat.io/redhat/redhat-operator-index:v4.16"; }
get_image_registry_and_repository() { echo "registry.redhat.io/redhat/redhat-operator-index"; }
render_opm() {
    local tmpfile; tmpfile=$(mktemp)
    echo '{"name":"test-operator","schema":"olm.package"}' > "$tmpfile"
    echo "$tmpfile"
}
extract_unique_package_names_from_catalog() { echo "test-operator"; }
get_unreleased_bundle() { echo "registry.redhat.io/test-operator/bundle:v1.0.0"; }
extract_related_images_from_bundle() { echo "registry.redhat.io/test-operator/operand:v1.0.0"; }
make_result_json() { echo '{"result":"test"}'; }
process_image_digest_mirror_set() { echo '{}'; }
MOCK_UTILS_EOF

fake_bin=$(mktemp -d) && cleanup+=("${fake_bin}")
cat > "${fake_bin}/opm" << 'OPM_MOCK'
#!/bin/bash
cat "${FBC_TEST_BUNDLE_JSON}"
OPM_MOCK
chmod +x "${fake_bin}/opm"
export PATH="${fake_bin}:${PATH}"

extract_script() {
  local script
  script="$(mktemp --tmpdir script_XXXXXXXXXX.sh)"
  yq -r ".spec.steps[] | select(.name == \"$1\").script" "${task_path}" > "${script}"

  sed -i "s|. /utils.sh|source ${mock_utils}|g" "${script}"
  sed -i 's|$(results.TEST_OUTPUT.path)|'"${results_dir}"'/TEST_OUTPUT|g' "${script}"
  sed -i 's|$(context.task.name)|fbc-fips-check|g' "${script}"
  sed -i "s|/tekton/home/|${tekton_home}/|g" "${script}"

  chmod +x "${script}"
  echo "${script}"
}

fips_check_script="$(extract_script get-unique-related-images)"
cleanup+=("${fips_check_script}")

# Build a minimal OPM bundle JSON fixture for testing FIPS exemption logic.
# The subscription value is a JSON-encoded array string (double-encoded in output)
# matching the real annotation format that the task's jq queries expect.
write_bundle_json() {
    local subscription="$1"
    local fips_compliant="${2:-}"
    local created_at="${3:-}"

    local args=(jq -n --arg sub "${subscription}")
    local template='{properties: [{type: "olm.csv.metadata", value: {annotations: {"operators.openshift.io/valid-subscription": $sub'

    if [ -n "${fips_compliant}" ]; then
        args+=(--arg fips "${fips_compliant}")
        template+=', "features.operators.openshift.io/fips-compliant": $fips'
    fi
    if [ -n "${created_at}" ]; then
        args+=(--arg date "${created_at}")
        template+=', "createdAt": $date'
    fi

    template+='}}}]}'
    "${args[@]}" "${template}" > "${FBC_TEST_BUNDLE_JSON}"
}

setup_test() {
    rm -f "${tekton_home}"/*.txt "${results_dir}"/*
}

Describe "FIPS exemption logic for FBC bundles"
    export IMAGE_URL=registry.io/test-operator/fbc-fragment:tag
    export IMAGE_DIGEST=sha256:abc123
    export SOURCE_CODE_DIR="${workspace_dir}"
    export IMAGE_MIRROR_SET_PATH=".tekton/images-mirror-set.yaml"

    BeforeEach setup_test

    It "exempts legacy bundle with qualifying subscription from FIPS check"
        write_bundle_json '["OpenShift Kubernetes Engine"]' '' '2024-06-15T00:00:00Z'
        When call "${fips_check_script}"
        The output should include "exempt from FIPS check"
        The output should include "Skipping FIPS static check"
        The output should include "No related images found"
        The status should be success
    End

    It "scans post-cutoff bundle with qualifying subscription"
        write_bundle_json '["OpenShift Kubernetes Engine"]' '' '2025-06-15T00:00:00Z'
        When call "${fips_check_script}"
        The output should include "Bundle created on or after FIPS requirement date"
        The output should include "Running the FIPS static check"
        The output should include "Unique related images"
        The status should be success
    End

    It "scans legacy bundle that explicitly claims FIPS compliance"
        write_bundle_json '["OpenShift Kubernetes Engine"]' 'true' '2024-06-15T00:00:00Z'
        When call "${fips_check_script}"
        The output should include "Legacy bundle claims fips-compliant=true"
        The output should include "Running FIPS static check to verify compliance"
        The output should include "Unique related images"
        The status should be success
    End

    It "skips bundles without qualifying Red Hat subscriptions"
        write_bundle_json '["Red Hat Developer Subscription"]' '' '2025-06-15T00:00:00Z'
        When call "${fips_check_script}"
        The output should include "not present in operators.openshift.io/valid-subscription"
        The output should include "Skipping the FIPS static check"
        The output should include "No related images found"
        The status should be success
    End
End
