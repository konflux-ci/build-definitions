#!/usr/bin/env bash

eval "$(shellspec -)"

# we're sourcing in the specs below, so `dirname $0` will return this script's directory
dirname() {
  echo ./appstudio-utils/util-scripts
}

Describe 'verify-attestation-with-policy'
  setup() {
    data_file=$(mktemp)
    echo '{"payload":"e30K"}'  > "${data_file}"
  }
  Before setup

  cleanup() {
    rm "${data_file}"
  }
  After cleanup

  It 'fails verifying if unable to fetch policies'
    export POLICY_REPO=bogus
    When run source ./appstudio-utils/util-scripts/verify-attestation-with-policy.sh "${data_file}" output.json result.json
    The output should include 'Fetching policies from main at bogus'
    The error should start with "fatal: 'bogus' does not appear to be a git repository"
    The status should be failure
  End
End
