#!/usr/bin/env bash

eval "$(shellspec -)"

EC_WORK_DIR=$(mktemp -d)
export EC_WORK_DIR

cleanup() {
  rm -rf "${EC_WORK_DIR}"
}
BeforeEach 'cleanup'

final_cleanup() {
  if [[ "${SHELLSPEC_KEEP_TMPDIR}" != "1" ]]; then
    rm -rf "${EC_WORK_DIR}"
  else
    echo "
Last test EC_WORK_DIR=${EC_WORK_DIR} manually remove it"
  fi
}
AfterAll 'final_cleanup'

Include ./appstudio-utils/util-scripts/lib/fetch.sh

Describe 'json-data-file'
  local root_dir=$( git rev-parse --show-toplevel )

  It 'produces expected json file paths'
    When call json-data-file some dir 123 foo 456
    The output should eq "$EC_WORK_DIR/data/some/dir/123/foo/456/data.json"
  End
End

Describe 'rekor-log-entry'
  rekor-cli() {
    echo "rekor-cli $*"
  }

  It 'calls rekor-cli as expected'
    When call rekor-log-entry 1234 rekor.example.com
    The output should eq "rekor-cli get --log-index 1234 --rekor_server https://rekor.example.com --format json"
  End
End

# We're not testing the data itself, but I think it's okay
#
Describe 'rekor-log-entry-save'
  json-data-file() {
    echo "/dev/null"
  }

  # Mock some fake rekor data
  rekor-log-entry() {
    if [[ $1 == 1235 ]]; then
      # With an attestation
      echo '{"foo":"bar","Attestation":"'$( echo '{"hey":"now"}' | base64 )'"}'
    else
      # Without an attestation
      echo '{"foo":"bar","Attestation":""}'
    fi
  }

  It 'saves rekor data without an attestation'
    When call rekor-log-entry-save 1234 rekor.example.com
    The output should eq "Saving log index 1234 from rekor.example.com"
  End

  It 'saves rekor data with an attestation'
    When call rekor-log-entry-save 1235 rekor.example.com
    The line 1 should eq "Saving log index 1235 from rekor.example.com"
    The line 2 should eq "Saving attestation extracted from rekor data"
  End


  # Put data in a file so we can look at it
  local tmp_file=$(mktemp --tmpdir)
  json-data-file() {
    echo $tmp_file
  }

  It 'saves log entry data'
    rekor-log-entry-save 1234 rekor.example.com > /dev/null
    The contents of file "$tmp_file" should eq \
'{
  "foo": "bar",
  "Attestation": ""
}'
  End

  It 'saves attestation data'
    rekor-log-entry-save 1235 rekor.example.com > /dev/null
    The contents of file "$tmp_file" should eq \
'{
  "hey": "now"
}'
  End

End

Describe 'git-fetch-policies'
  git() {
    echo "git $*"
  }

  local repo=hacbs-contract
  local ref=main

  It 'does a git fetch'
    When call git-fetch-policies
    The output should eq \
"Fetching policies from $ref at https://github.com/$repo/ec-policies.git
sha: git init -q .
git fetch -q --depth 1 --no-tags https://github.com/$repo/ec-policies.git $ref
git checkout -q FETCH_HEAD
git rev-parse FETCH_HEAD"
  End

End

Describe 'shorten-sha'
  local sha="beefba5eba11decade"
  local short_sha="beefba5eba1"

  Parameters
    # Expect prefix to be trimmed and sha to be shortened
    "$sha"
    "sha256:$sha"
    "sha512:$sha"
    "sha512/224:$sha"

    # Presumably bad data, expect prefix to be left alone
    "shalala:$sha" "shalala:bee"
    "foo:$sha" "foo:beefba5"
  End

  Example "Shortening sha string '$1'"
    When call shorten-sha "$1"
    The output should eq "${2:-$short_sha}"
  End

End

Describe 'save-policy-config'

  Describe 'fetches from config map'
    Mock oc
      oc_args=$*
      %preserve oc_args
      echo '{"from": "cluster"}'
    End

    It 'fetches policy from configmap'
      When call save-policy-config
      The variable oc_args should eq 'get configmap ec-policy -o go-template={{index .data "policy.json"}}'
      The contents of file "${EC_WORK_DIR}/data/config/policy/data.json" should eq '{
  "from": "cluster"
}'
    End
  End

  Describe 'default fallback when configmap is not present'
    Mock oc
      exit 1
    End

    It 'fallsback to default'
      When call save-policy-config
      The contents of file "${EC_WORK_DIR}/data/config/policy/data.json" should eq '{
  "non_blocking_checks": [
    "not_useful"
  ]
}'
    End
  End

End

# Todo: Coverage for liblib/fetch/tekon
