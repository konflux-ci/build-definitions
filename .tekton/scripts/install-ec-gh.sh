#!/usr/bin/env bash
set -euo pipefail

ARCH=$(uname -m)
if [ "$ARCH" = "x86_64" ]; then ARCH="amd64"; elif [ "$ARCH" = "aarch64" ]; then ARCH="arm64"; fi

BIN_DIR="/tmp/bin"
mkdir -p "$BIN_DIR"
export PATH="$BIN_DIR:$PATH"

retry curl -fsSL "https://github.com/conforma/cli/releases/download/snapshot/ec_linux_${ARCH}" -o "$BIN_DIR/ec"
retry curl -fsSL "https://github.com/conforma/cli/releases/download/snapshot/ec_linux_${ARCH}.sha256" -o /tmp/ec.sha256
echo "$(awk '{print $1}' /tmp/ec.sha256)  $BIN_DIR/ec" | sha256sum -c -
chmod +x "$BIN_DIR/ec"
rm -f /tmp/ec.sha256

GH_VERSION="2.60.1"
retry curl -fsSL "https://github.com/cli/cli/releases/download/v${GH_VERSION}/gh_${GH_VERSION}_linux_${ARCH}.tar.gz" -o /tmp/gh.tar.gz
retry curl -fsSL "https://github.com/cli/cli/releases/download/v${GH_VERSION}/gh_${GH_VERSION}_checksums.txt" -o /tmp/gh_checksums.txt
grep "gh_${GH_VERSION}_linux_${ARCH}.tar.gz" /tmp/gh_checksums.txt | awk '{print $1 "  /tmp/gh.tar.gz"}' | sha256sum -c -
tar -xz -C "$BIN_DIR" --strip-components=2 --no-same-owner -f /tmp/gh.tar.gz "gh_${GH_VERSION}_linux_${ARCH}/bin/gh"
rm -f /tmp/gh.tar.gz /tmp/gh_checksums.txt
