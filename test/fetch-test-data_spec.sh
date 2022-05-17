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

Include ./appstudio-utils/util-scripts/fetch-test-data.sh

# This is not included in lib/fetch.sh and more, but include
# it here so the rekor tests below continue to pass
Include ./appstudio-utils/util-scripts/lib/fetch/rekor.sh

Describe 'cr_* helpers'
  Parameters
    'empty'
    'namespace not given' policy policy
    'namespace given' namespace/policy policy '-n namespace'
    'odd' /policy policy
    'even more odd' namespace/ '' '-n namespace'
  End

  It "handles $1 case for name"
    When call cr_name "${2:-}"
    The output should equal "${3:-}"
  End

  It "handles $1 case for namespace argument"
    When call cr_namespace_argument "${2:-}"
    The output should equal "${4:-}"
  End
End

Describe 'json_data_file'
  local root_dir=$( git rev-parse --show-toplevel )

  It 'produces expected json file paths'
    When call json_data_file some dir 123 foo 456
    The output should eq "$EC_WORK_DIR/data/some/dir/123/foo/456/data.json"
  End
End

Describe 'rekor_log_entry'
  Mock rekor-cli
    echo "rekor-cli $*"
  End

  It 'calls rekor-cli as expected'
    When call rekor_log_entry 1234 rekor.example.com
    The output should eq "rekor-cli get --log-index 1234 --rekor_server https://rekor.example.com --format json"
  End
End

# We're not testing the data itself, but I think it's okay
#
Describe 'rekor_log_entry_save'
  json_data_file() {
    echo "/dev/null"
  }

  # Mock some fake rekor data
  rekor_log_entry() {
    if [[ $1 == 1235 ]]; then
      # With an attestation
      echo '{"foo":"bar","Attestation":"'$( echo '{"hey":"now"}' | base64 )'"}'
    else
      # Without an attestation
      echo '{"foo":"bar","Attestation":""}'
    fi
  }

  It 'saves rekor data without an attestation'
    When call rekor_log_entry_save 1234 rekor.example.com
    The output should eq "Saving log index 1234 from rekor.example.com"
  End

  It 'saves rekor data with an attestation'
    When call rekor_log_entry_save 1235 rekor.example.com
    The line 1 should eq "Saving log index 1235 from rekor.example.com"
    The line 2 should eq "Saving attestation extracted from rekor data"
  End


  # Put data in a file so we can look at it
  local tmp_file=$(mktemp --tmpdir)
  json_data_file() {
    echo $tmp_file
  }

  It 'saves log entry data'
    rekor_log_entry_save 1234 rekor.example.com > /dev/null
    The contents of file "$tmp_file" should eq \
'{
  "foo": "bar",
  "Attestation": ""
}'
  End

  It 'saves attestation data'
    rekor_log_entry_save 1235 rekor.example.com > /dev/null
    The contents of file "$tmp_file" should eq \
'{
  "hey": "now"
}'
  End

End

Describe 'git_fetch_policies'
  git() {
    echo "git $*"
  }

  Mock kubectl
    # fail to fetch EnterpriseContractPolicy by default
    exit 1
  End

  local repo=hacbs-contract
  local ref=main

  It 'does a git fetch'
    When call git_fetch_policies
    The output should start with "Fetching policies from $ref at https://github.com/$repo/ec-policies.git"
  End

  It 'does a git fetch from a custom repository'
    export POLICY_REPO=https://github.com/custom/policies.git
    When call git_fetch_policies
    The output should start with "Fetching policies from $ref at https://github.com/custom/policies.git"
  End

  It 'does a git fetch from a custom repository and reference'
    export POLICY_REPO=https://github.com/custom/policies.git
    export POLICY_REPO_REF=abcd
    When call git_fetch_policies
    The output should start with 'Fetching policies from abcd at https://github.com/custom/policies.git'
  End

  Describe 'from ECP resource'
    Parameters
      'without namespace'       'custom-policy'                  'custom-policy'
      'with namespace and name' 'custom-namespace/custom-policy' '-n custom-namespace custom-policy'
    End

    It "does a git fetch with configuration from custom resource $1"
      Mock kubectl
        kubectl_args="$*"
        %preserve kubectl_args
        echo 'https://github.com/custom/policies.git#custom-ref'
      End

      When call git_fetch_policies "$2"
      The variable kubectl_args should start with "get enterprisecontractpolicies.appstudio.redhat.com $3 -o jsonpath="
      The output should start with 'Fetching policies from custom-ref at https://github.com/custom/policies.git'
    End
  End

  It 'can fail to fetch from ECP resource'
    Mock kubectl
      kubectl_args="$*"
      %preserve kubectl_args
      exit 1 # fails to fetch
    End

    When call git_fetch_policies ns/policy
    The variable kubectl_args should start with 'get enterprisecontractpolicies.appstudio.redhat.com -n ns policy -o jsonpath='
    The output should start with "Fetching policies from $ref at https://github.com/$repo/ec-policies.git"
  End

End

Describe 'shorten_sha'
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
    When call shorten_sha "$1"
    The output should eq "${2:-$short_sha}"
  End

End

Describe 'save_policy_config'

  Describe 'fetches from config map'
    Mock oc
      oc_args=$*
      if [[ "${oc_args}" =~ enterprisecontractpolicies ]]; then
        exit 1
      fi
      %preserve oc_args
      echo '{"from": "cluster"}'
    End

    Mock kubectl
      if [[ "$*" =~ enterprisecontractpolicies ]]; then
        exit 1
      fi
      # fetching the current namespace for the error message
      echo test
    End

    It 'fetches policy from configmap'
      When call save_policy_config
      The error should equal 'ERROR: unable to find the ec-policy EnterpriseContractPolicy in namespace test'
      The variable oc_args should eq 'get configmap ec-policy -o go-template={{index .data "policy.json"}}'
      The contents of file "${EC_WORK_DIR}/data/config/policy/data.json" should eq '{
  "from": "cluster"
}'
    End
  End

  Describe 'default fallback when configmap is not present'
    Mock kubectl
      if [[ "$*" =~ enterprisecontractpolicies ]]; then
        exit 1
      fi
      # needed for fetching the current namespace for the error message
      echo test
    End

    Mock oc
      # used for fetching the config map
      exit 1
    End

    It 'fallsback to default'
      When call save_policy_config
      The error should equal 'ERROR: unable to find the ec-policy EnterpriseContractPolicy in namespace test'
      The contents of file "${EC_WORK_DIR}/data/config/policy/data.json" should eq '{
  "non_blocking_checks": [
    "not_useful"
  ]
}'
    End
  End

  Describe 'fetches from custom resource'
    Mock kubectl
      kubectl_args=$*
      %preserve kubectl_args
      echo '["a", "b", "c"]'
    End

    It 'fetches policy custom resource'
      When call save_policy_config custom-policy
      The variable kubectl_args should start with 'get enterprisecontractpolicies.appstudio.redhat.com custom-policy'
      The contents of file "${EC_WORK_DIR}/data/config/policy/non_blocking_checks/data.json" should eq "$(echo '["a", "b", "c"]'| jq)"
    End

    It 'fetches policy custom resource in namespace'
      When call save_policy_config custom-namespace/custom-policy
      The variable kubectl_args should start with 'get enterprisecontractpolicies.appstudio.redhat.com -n custom-namespace custom-policy'
      The contents of file "${EC_WORK_DIR}/data/config/policy/non_blocking_checks/data.json" should eq "$(echo '["a", "b", "c"]'| jq)"
    End

    It 'can fail to fetch from custom resource'
      Mock kubectl
        kubectl_args=$*
        %preserve kubectl_args
        exit 1
      End
      Mock oc
        # used for fetching the config map
        exit 1
      End
      When call save_policy_config custom-namespace/custom-policy
      The variable kubectl_args should start with 'get enterprisecontractpolicies.appstudio.redhat.com -n custom-namespace custom-policy'
      The error should equal 'ERROR: unable to find the ec-policy EnterpriseContractPolicy in namespace custom-namespace'
      The file "${EC_WORK_DIR}/data/config/policy/non_blocking_checks/data.json" should not exist
      The status should be failure
    End
  End

  Describe 'handles errors from cr_* functions'
    # When a function is on a call path originating from shellspec the errexit
    # option seems to be ignored and the execution proceeds regardless of the
    # status, e.g.
    #
    # ```
    # function f() {
    #   set -e
    #   fail 2>/dev/null
    #   echo "Should not be here: status was $?"
    # }
    # 
    # Describe 'error handling'
    #   It 'no worky'
    #     When call f
    #     The the status should be failure
    #   End
    # End
    # ```
    #
    # Always fails the test
    Skip "can't figure out how to test error handling with shellspec"
    Mock kubectl
      kubectl_args=$*
      %preserve kubectl_args
    End

    It 'fails if cr-name fails'
      Mock cr_name
        exit 1
      End
      When call save_policy_config custom-namespace/custom-policy
      The variable kubectl_args should equal ''
    End

    It 'fails if cr-namespace-argument fails'
      Mock cr_namespace_argument
        exit 1
      End
      When call save_policy_config custom-namespace/custom-policy
      The variable kubectl_args should equal ''
    End

  End

End

# Todo: Coverage for liblib/fetch/tekon
