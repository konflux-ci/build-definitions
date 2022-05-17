#!/usr/bin/env bash
# Runs cosign verify to verify the signature of the provided image
# reference with the provided public key
# usage:
#   cosign-verify.sh <image reference> <public key> <output file>
# where:
#   <image reference> string pointing to the image, e.g.
#                     registry-host/image:tag
#   <public key>      PEM-encoded string or a valid cosign key reference
#                     e.g. '-----BEGIN PUBLIC KEY-----\n...' or
#                     k8s://default/testsecret
#   <output file>     where to store the result in JSON format

set -euo pipefail

cosign_verify() {
  local image_reference="$1"

  local public_key="$2"
  if [[ "${public_key}" == -----BEGIN* ]]; then
    local tmp_public_key
    tmp_public_key="$(mktemp)"
    # shellcheck disable=SC2064
    # - we want this to expand here as $tmp_public_key is a local variable
    trap "rm '${tmp_public_key}'" EXIT
    echo "${public_key}" > "${tmp_public_key}"
    public_key="${tmp_public_key}"
  fi

  local output_file="$3"

  cosign verify \
    --key "${public_key}" \
    --output-file "${output_file}" \
    "${image_reference}"
}

# When included from shellspec we don't want to invoke cosign_verify
${__SOURCED__:+return}

cosign_verify "$1" "$2" "$3"
