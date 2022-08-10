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

Describe 'cr-* helpers'
  Parameters
    'empty'
    'namespace not given' policy policy
    'namespace given' namespace/policy policy '-n namespace'
    'odd' /policy policy
    'even more odd' namespace/ '' '-n namespace'
  End

  It "handles $1 case for name"
    When call cr-name "${2:-}"
    The output should equal "${3:-}"
  End

  It "handles $1 case for namespace argument"
    When call cr-namespace-argument "${2:-}"
    The output should equal "${4:-}"
  End
End

Describe 'json-data-file'
  local root_dir=$( git rev-parse --show-toplevel )

  It 'produces expected json file paths'
    When call json-data-file some dir 123 foo 456
    The output should eq "$EC_WORK_DIR/data/some/dir/123/foo/456/data.json"
  End
End

Describe 'git-fetch-policies'
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
    When call git-fetch-policies
    The output should start with "Fetching policies from $ref at https://github.com/$repo/ec-policies.git"
  End

  It 'does a git fetch from a custom repository'
    export POLICY_REPO=https://github.com/custom/policies.git
    When call git-fetch-policies
    The output should start with "Fetching policies from $ref at https://github.com/custom/policies.git"
  End

  It 'does a git fetch from a custom repository and reference'
    export POLICY_REPO=https://github.com/custom/policies.git
    export POLICY_REPO_REF=abcd
    When call git-fetch-policies
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

      When call git-fetch-policies "$2"
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

    When call git-fetch-policies ns/policy
    The variable kubectl_args should start with 'get enterprisecontractpolicies.appstudio.redhat.com -n ns policy -o jsonpath='
    The output should start with "Fetching policies from $ref at https://github.com/$repo/ec-policies.git"
  End

End

# Todo: Coverage for liblib/fetch/tekon
