#!/bin/bash
set -euo pipefail

SCRIPT_DIR=$(dirname "$(realpath "$0")")
TASK_FILE=${1:-"$SCRIPT_DIR/../build-vm-image.yaml"}
TEST_DIR=$(mktemp -d "${TMPDIR:-/tmp}/bib-overlay.XXXXXXXXXX")
TEST_DIR=$(realpath "$TEST_DIR")
trap 'rm -rf "$TEST_DIR"' EXIT

# macOS realpath lacks -m; keep actual filesystem resolution in local tests.
if [[ $(uname -s) == Darwin ]]; then
  realpath() {
    if [[ ${1:-} == -m ]]; then
      python3 -c 'import os, sys; print(os.path.realpath(sys.argv[1]))' "$2"
    else
      command realpath "$@"
    fi
  }
  export -f realpath
fi

WORK_DIR="$TEST_DIR/work"
mkdir -p "$WORK_DIR/source"
VALIDATE_SCRIPT=$(yq -r '.spec.steps[] | select(.name == "validate-config") | .script' "$TASK_FILE")
VALIDATE_SCRIPT=${VALIDATE_SCRIPT//\/var\/workdir/$WORK_DIR}
export IMAGE_TYPE=ami STORAGE_DRIVER=vfs SBOM_TYPE=spdx
export BIB_CONFIG_FILE=bib.yaml
export CONFIG_TOML_FILE=base.toml CONFIG_TOML_OVERLAY_FILE=overlay.toml

cat > "$WORK_DIR/source/bib.yaml" <<'EOF'
bootc-builder-image: quay.io/example/builder:latest
source-image: quay.io/example/source:latest
EOF

reset_config() {
  rm -f "$WORK_DIR/config.json" "$WORK_DIR/base-config.json" "$WORK_DIR/overlay-config.json" "$WORK_DIR/vars" "$WORK_DIR/source/base.toml" "$WORK_DIR/source/overlay.toml"
  export CONFIG_TOML_FILE=base.toml CONFIG_TOML_OVERLAY_FILE=overlay.toml
  cat > "$WORK_DIR/source/base.toml" <<'EOF'
[customizations.kernel]
name = "customizations-for-provider"
append = "console=ttyS0 net.ifnames=0"
EOF
  cat > "$WORK_DIR/source/overlay.toml" <<'EOF'
[[customizations.filesystem]]
mountpoint = "/"
minsize = "100 GiB"
EOF
}

validate_config() {
  bash -c "$VALIDATE_SCRIPT" > "$TEST_DIR/validate.log" 2>&1
}

expect_success() {
  if ! validate_config; then
    cat "$TEST_DIR/validate.log"
    echo "FAIL: $1" >&2
    exit 1
  fi
}

expect_failure() {
  if validate_config; then
    echo "FAIL: $1 was accepted" >&2
    exit 1
  fi
  if ! grep -q "$2" "$TEST_DIR/validate.log"; then
    cat "$TEST_DIR/validate.log"
    echo "FAIL: $1 failed for the wrong reason" >&2
    exit 1
  fi
  echo "PASS: $1 rejected"
}

expect_invalid_toml() {
  expect_failure "$1" "invalid TOML"
  if [[ -e "$WORK_DIR/base-config.json" || -e "$WORK_DIR/overlay-config.json" || -e "$WORK_DIR/config.json" ]]; then
    echo "FAIL: $1 was converted before rejection" >&2
    exit 1
  fi
}

reset_config
BASE_CHECKSUM=$(cksum < "$WORK_DIR/source/base.toml")
OVERLAY_CHECKSUM=$(cksum < "$WORK_DIR/source/overlay.toml")
expect_success "add root minimum"
jq -e '.customizations == {
  "kernel": {"name": "customizations-for-provider", "append": "console=ttyS0 net.ifnames=0"},
  "filesystem": [{"mountpoint": "/", "minsize": "100 GiB"}]
}' "$WORK_DIR/config.json" > /dev/null
[[ $(cksum < "$WORK_DIR/source/base.toml") == "$BASE_CHECKSUM" ]]
[[ $(cksum < "$WORK_DIR/source/overlay.toml") == "$OVERLAY_CHECKSUM" ]]
# shellcheck source=/dev/null
source "$WORK_DIR/vars"
[[ $BIB_CUSTOM_CONFIG_FILE == "$WORK_DIR/config.json" ]]
[[ $BIB_CUSTOM_CONFIG_NAME == config.json ]]
[[ $BIB_CUSTOM_CONFIG_ARGUMENT == --config=/config.json ]]
echo "PASS: root minimum added, kernel preserved, inputs unchanged, JSON selected"

reset_config
cat >> "$WORK_DIR/source/base.toml" <<'EOF'

[[customizations.filesystem]]
mountpoint = "/boot"
minsize = "2 GiB"

[[customizations.filesystem]]
mountpoint = "/"
minsize = "80 GiB"

[[customizations.filesystem]]
mountpoint = "/home"
minsize = "10 GiB"
EOF
cat > "$WORK_DIR/source/overlay.toml" <<'EOF'
[[customizations.filesystem]]
mountpoint = "/"
minsize = "120 GiB"
EOF
expect_success "override existing root"
jq -e '.customizations.filesystem == [
  {"mountpoint": "/boot", "minsize": "2 GiB"},
  {"mountpoint": "/", "minsize": "120 GiB"},
  {"mountpoint": "/home", "minsize": "10 GiB"}
]' "$WORK_DIR/config.json" > /dev/null
echo "PASS: configurable minimum overrides root by mountpoint and preserves other filesystems"

reset_config
cat >> "$WORK_DIR/source/base.toml" <<'EOF'

[[customizations.filesystem]]
mountpoint = "/"
size = "80 GiB"

[[customizations.filesystem]]
mountpoint = "/boot"
size = "2 GiB"
EOF
expect_success "normalize legacy filesystem size"
jq -e '.customizations.filesystem == [
  {"mountpoint": "/", "minsize": "100 GiB"},
  {"mountpoint": "/boot", "minsize": "2 GiB"}
]' "$WORK_DIR/config.json" > /dev/null
echo "PASS: legacy filesystem size normalized for JSON"

reset_config
cat >> "$WORK_DIR/source/base.toml" <<'EOF'

[[customizations.filesystem]]
mountpoint = "/"
minsize = "80 GiB"

[[customizations.filesystem]]
mountpoint = "/"
minsize = "90 GiB"
EOF
expect_failure "duplicate base mountpoints" "duplicate mountpoint"

reset_config
cat >> "$WORK_DIR/source/overlay.toml" <<'EOF'

[[customizations.filesystem]]
mountpoint = "/"
minsize = "120 GiB"
EOF
expect_failure "duplicate overlay mountpoints" "duplicate mountpoint"

reset_config
cat >> "$WORK_DIR/source/overlay.toml" <<'EOF'

[customizations.kernel]
append = "downstream-kernel-args"
EOF
expect_failure "non-filesystem overlay" "only customizations.filesystem"

reset_config
cat >> "$WORK_DIR/source/overlay.toml" <<'EOF'
unexpected = "field"
EOF
expect_failure "unsupported filesystem overlay field" "unsupported filesystem"

reset_config
cat > "$WORK_DIR/source/overlay.toml" <<'EOF'
[customizations.filesystem]
mountpoint = "/"
minsize = "100 GiB"
EOF
expect_failure "filesystem table instead of array" "filesystem must be an array"

reset_config
cat > "$WORK_DIR/source/base.toml" <<'EOF'
[customizations]
filesystem = false
EOF
expect_failure "base filesystem boolean instead of array" "filesystem must be an array"

reset_config
cat > "$WORK_DIR/source/overlay.toml" <<'EOF'
[[customizations.filesystem]]
minsize = "100 GiB"
EOF
expect_failure "missing mountpoint" "mountpoint"

for size in true 0 -1 '""'; do
  reset_config
  cat > "$WORK_DIR/source/overlay.toml" <<EOF
[[customizations.filesystem]]
mountpoint = "/"
minsize = $size
EOF
  expect_failure "invalid minsize $size" "minsize"
done

reset_config
cat >> "$WORK_DIR/source/base.toml" <<'EOF'

[[customizations.filesystem]]
mountpoint = "/"
size = "80 GiB"
minsize = "90 GiB"
EOF
expect_failure "conflicting legacy size and minsize" "size and minsize"

reset_config
cat >> "$WORK_DIR/source/overlay.toml" <<'EOF'
minsize = "1 GiB"
EOF
expect_invalid_toml "duplicate overlay minsize key"

reset_config
cat >> "$WORK_DIR/source/base.toml" <<'EOF'
append = "replacement-kernel-args"
EOF
expect_invalid_toml "duplicate base kernel key"

reset_config
cat > "$WORK_DIR/source/overlay.toml" <<'EOF'
[customizations]
filesystem = [{ mountpoint = "/", minsize = "100 GiB" }]
[customizations]
filesystem = [{ mountpoint = "/", minsize = "1 GiB" }]
EOF
expect_invalid_toml "duplicate overlay table"

reset_config
cat >> "$WORK_DIR/source/base.toml" <<'EOF'

[customizations.kernel]
name = "replacement"
append = "replacement-kernel-args"
EOF
expect_invalid_toml "duplicate base kernel table"

reset_config
printf '[invalid\n' > "$WORK_DIR/source/overlay.toml"
expect_failure "malformed overlay TOML" "Error"

reset_config
rm "$WORK_DIR/source/overlay.toml"
expect_failure "missing overlay file" "CONFIG_TOML_OVERLAY_FILE"

reset_config
rm "$WORK_DIR/source/base.toml"
expect_failure "missing base file" "CONFIG_TOML_FILE"

reset_config
export CONFIG_TOML_FILE=""
expect_failure "overlay without explicit base" "requires CONFIG_TOML_FILE"

for param in CONFIG_TOML_FILE CONFIG_TOML_OVERLAY_FILE; do
  reset_config
  export "$param=../outside.toml"
  expect_failure "$param path escape" "escapes source directory"

  reset_config
  cp "$WORK_DIR/source/overlay.toml" "$WORK_DIR/outside.toml"
  ln -s "$WORK_DIR/outside.toml" "$WORK_DIR/source/escape.toml"
  export "$param=escape.toml"
  expect_failure "$param symlink escape" "escapes source directory"
  rm "$WORK_DIR/source/escape.toml"
done

reset_config
export CONFIG_TOML_OVERLAY_FILE=""
expect_success "no overlay"
[[ ! -e "$WORK_DIR/config.json" ]]
# shellcheck source=/dev/null
source "$WORK_DIR/vars"
[[ $BIB_CUSTOM_CONFIG_FILE == "$WORK_DIR/source/base.toml" ]]
[[ $BIB_CUSTOM_CONFIG_NAME == config.toml ]]
[[ -z $BIB_CUSTOM_CONFIG_ARGUMENT ]]
echo "PASS: no-overlay caller retains single-TOML behavior"

reset_config
export CONFIG_TOML_FILE="" CONFIG_TOML_OVERLAY_FILE=""
expect_success "default config fallback"
# shellcheck source=/dev/null
source "$WORK_DIR/vars"
[[ $BIB_CUSTOM_CONFIG_FILE == "$WORK_DIR/source/config.toml" ]]
[[ $BIB_CUSTOM_CONFIG_NAME == config.toml ]]
[[ -z $BIB_CUSTOM_CONFIG_ARGUMENT ]]
echo "PASS: default config fallback retained"
