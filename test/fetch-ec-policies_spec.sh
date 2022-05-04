#!/usr/bin/env bash

eval "$(shellspec -)"

# we're sourcing in the specs below, so `dirname $0` will return this script's directory
dirname() {
  echo ./appstudio-utils/util-scripts
}

Describe 'fetch-ec-policies'
  It 'fails fetching from bogus repositories'
    POLICY_REPO=bogus
    When run source ./appstudio-utils/util-scripts/fetch-ec-policies.sh
    The output should include 'Fetching policies from main at bogus'
    The error should start with "fatal: 'bogus' does not appear to be a git repository"
    The status should be failure
  End
End
