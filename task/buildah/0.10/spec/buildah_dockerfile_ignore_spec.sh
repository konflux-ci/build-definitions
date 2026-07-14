#!/bin/env bash

set -o errexit
set -o pipefail
set -o nounset

eval "$(shellspec - -c) exit 1"

task_path=buildah.yaml
if [[ -f "../${task_path}" ]]; then
    task_path="../${task_path}"
fi

# Extract the ignorefile detection block from the task YAML and wrap it as a
# callable function. This avoids duplicating the logic in the test.
extract_ignorefile_fn() {
  local script
  script="$(yq -r '.spec.steps[] | select(.name == "build").script' "${task_path}")"
  local block
  block="$(echo "$script" | sed -n '/^[[:space:]]*ignorefile_args=()/,/^[[:space:]]*fi$/p')"
  local fn
  fn="$(mktemp --tmpdir ignorefile_fn_XXXXXXXXXX.sh)"
  cat > "$fn" <<FNEOF
#!/bin/bash
set -euo pipefail
dockerfile_path="\$1"
${block}
echo "\${ignorefile_args[*]:-}"
FNEOF
  chmod +x "$fn"
  echo "$fn"
}

ignorefile_fn="$(extract_ignorefile_fn)"
cleanup=("$ignorefile_fn")
trap 'rm -rf "${cleanup[@]}"' EXIT

Describe "per-Dockerfile ignore file detection"
  setup_tmpdir() {
    TEST_TMPDIR="$(mktemp -d)"
    cleanup+=("$TEST_TMPDIR")
    touch "$TEST_TMPDIR/Dockerfile"
  }
  BeforeEach 'setup_tmpdir'

  It "uses .containerignore when only .containerignore exists"
    setup() { touch "$TEST_TMPDIR/Dockerfile.containerignore"; }
    BeforeCall 'setup'
    When call "$ignorefile_fn" "$TEST_TMPDIR/Dockerfile"
    The output should include "-- --ignorefile"
    The output should include ".containerignore"
  End

  It "uses .dockerignore when only .dockerignore exists"
    setup() { touch "$TEST_TMPDIR/Dockerfile.dockerignore"; }
    BeforeCall 'setup'
    When call "$ignorefile_fn" "$TEST_TMPDIR/Dockerfile"
    The output should include "-- --ignorefile"
    The output should include ".dockerignore"
  End

  It "prefers .containerignore over .dockerignore when both exist"
    setup() {
      touch "$TEST_TMPDIR/Dockerfile.containerignore"
      touch "$TEST_TMPDIR/Dockerfile.dockerignore"
    }
    BeforeCall 'setup'
    When call "$ignorefile_fn" "$TEST_TMPDIR/Dockerfile"
    The output should include ".containerignore"
    The output should not include ".dockerignore"
  End

  It "produces empty output when no per-Dockerfile ignore file exists"
    When call "$ignorefile_fn" "$TEST_TMPDIR/Dockerfile"
    The output should equal ""
  End

  It "works with a Dockerfile in a subdirectory"
    setup() {
      mkdir -p "$TEST_TMPDIR/test/e2e"
      touch "$TEST_TMPDIR/test/e2e/Dockerfile"
      touch "$TEST_TMPDIR/test/e2e/Dockerfile.dockerignore"
    }
    BeforeCall 'setup'
    When call "$ignorefile_fn" "$TEST_TMPDIR/test/e2e/Dockerfile"
    The output should include "-- --ignorefile"
    The output should include "test/e2e/Dockerfile.dockerignore"
  End

  It "works with a non-default Containerfile name"
    setup() {
      touch "$TEST_TMPDIR/Containerfile.build"
      touch "$TEST_TMPDIR/Containerfile.build.containerignore"
    }
    BeforeCall 'setup'
    When call "$ignorefile_fn" "$TEST_TMPDIR/Containerfile.build"
    The output should include "-- --ignorefile"
    The output should include "Containerfile.build.containerignore"
  End
End
