#!/usr/bin/env bash

eval "$(shellspec -)"

Include ./appstudio-utils/util-scripts/lib/fetch/git.sh

setup() {
  git_repository="$(mktemp -d)"
  work_dir="$(mktemp -d)"
}
Before 'setup'

cleanup() {
  rm -rf "${git_repository}"
  rm -rf "${work_dir}"
}
After 'cleanup'

Describe 'git-fetch-repo'
  rev_main=""
  rev_branch=""

  setup_repo() {
    cd "${git_repository}" || exit
    git init -q -b main
    echo main > file
    git add file
    git commit -q -m initial file
    rev_main="$(git rev-parse HEAD)"
    git checkout -q -b branch
    echo branch > file
    git commit -a -q -m branch
    rev_branch="$(git rev-parse HEAD)"
  }

  Before setup_repo

  zero_tags() {
    cd "${work_dir}" || exit
    [ "$(git tag |wc -l)" == "0" ]
  }

  one_branch() {
    cd "${work_dir}" || exit
    [ "$(git branch |wc -l)" == "1" ]
  }

  It 'fetches'
    When call git-fetch-repo "${git_repository}" main "${work_dir}"
    The contents of file "${work_dir}/file" should equal 'main'
    The output should equal "${rev_main}"
    The result of 'zero_tags()' should be successful
    The result of 'one_branch()' should  be successful
  End

  It 'fetches from different branch'
    When call git-fetch-repo "${git_repository}" branch "${work_dir}"
    The contents of file "${work_dir}/file" should equal 'branch'
    The output should equal "${rev_branch}"
    The result of 'zero_tags()' should be successful
    The result of 'one_branch()' should  be successful
  End

  It 'fails on bogus repository'
    When call git-fetch-repo bogus main "${work_dir}"
    The status should be failure
    The error should start with "fatal: 'bogus' does not appear to be a git repository"
    The file "${work_dir}/.git/FETCH_HEAD" should be empty file
  End

  It 'fails on bogus ref'
    When call git-fetch-repo "${git_repository}" bogus "${work_dir}"
    The status should be failure
    The error should start with "fatal: couldn't find remote ref bogus"
    The file "${work_dir}/.git/FETCH_HEAD" should be empty file
  End
End

Describe 'git-fetch-policies'
  POLICY_REPO_REF=main
  POLICY_REPO=repo
  POLICIES_DIR=dir

  It 'fetches policies'
    git-fetch-repo() {
      args="$*"
      %preserve args
      echo sha-here
    }

    When call git-fetch-policies
    The output should equal 'Fetching policies from main at repo
sha: sha-here'
    The variable args should eq 'repo main dir'
  End

  It 'can fail to fetch policies'
    git-fetch-repo() {
      exit 1
    }

    When call git-fetch-policies
    The output should equal 'Fetching policies from main at repo
Unable to fetch polices repository from repo at ref main!'
    The status should be failure
  End
End
