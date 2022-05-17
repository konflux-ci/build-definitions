#!/usr/bin/env bash

eval "$(shellspec -)"

Describe 'cosign_verify_attestation'

  cosign() {
    echo "cosign $*"
  }

  keyfile="$(mktemp)"
  mktemp() {
    echo "${keyfile}"
  }

  Include ./appstudio-utils/util-scripts/cosign-verify-attestation.sh

  It 'handles PEM encoded public keys'
    key='-----BEGIN PUBLIC KEY-----
MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAENE67fL1rVd0BpkpTV9l4laKUYcw+
Bq96Z52dLcyol7c1B3dm1T/BMusAu139o6e7gWxJZuOnMpqOAO3SwQ1LYg==
-----END PUBLIC KEY-----'
    When call cosign_verify_attestation image_ref "${key}" output_file
    The output should match pattern "cosign verify-attestation --key ${keyfile} --output-file output_file image_ref"
    The contents of file "${keyfile}" should equal "${key}"
  End

  It 'handles cosign key references'
    When call cosign_verify_attestation image_ref k8s://default/testsecret output_file
    The output should eq "cosign verify-attestation --key k8s://default/testsecret --output-file output_file image_ref"
  End

End
