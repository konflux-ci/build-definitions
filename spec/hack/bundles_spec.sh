#!/bin/bash
# this spec file tests creating Tekton bundles and the acceptable bundles list

set -o errexit
set -o pipefail
set -o nounset

eval "$(shellspec - -c) exit 1"

check_tkn_push_url() {
  while read -r line; do
    if [[ "$line" == quay.io/* ]] && [[ ! "$line" =~ ^quay\.io/[a-zA-Z0-9_-]+/[a-zA-Z0-9_-]+:[0-9a-zA-Z\.-]+@sha256:[a-fA-F0-9]+$ ]]; then
      return 1
    fi
  done
}

create_test_tasks() {
    mkdir -p tmp/task1/0.1
    mkdir -p tmp/task2/0.1
    touch tmp/task1/0.1/task1.yaml
    touch tmp/task2/0.1/task2.yaml
}

cleanup_test_data() {
    rm -rf tmp
    rm -f test-task-bundle-list
    rm -f test-task-bundle-list.csv
}

Describe "Creating new acceptable bundles"
    AfterAll 'cleanup_test_data'

    Mock skopeo
      # Make the skopeo inspect command fail
      if [ "$1" = "inspect" ]; then
        return 1
      fi
    End

    Mock tkn
      echo "${5}@sha256:5678"
    End

    Mock sha256sum
      echo "1234"
    End

    Mock ec
    End

    Mock find
        echo "tmp/task1/0.1/\ntmp/task2/0.1/"
    End

    It "builds bundles with the correct sha as the tag"
        create_test_tasks
        Mock git
            echo "1234"
        End
        export OUTPUT_TASK_BUNDLE_LIST=test-task-bundle-list
        export QUAY_NAMESPACE=konflux-ci
        export SKIP_BUILD=true

        When call "hack/build-and-push.sh"
        The status should be success
        # each task and pipeline bundle ends with file checksum @ digest
        The output should satisfy check_tkn_push_url
    End

    It 'processes the bundles and generates the correct output file'
        # this is only used for the task_records var which is unused in this test
        Mock git
            echo "task/task1/task1.yaml\ntask/task2/task2.yaml"
        End

        export OUTPUT_TASK_BUNDLE_LIST="test-task-bundle-list.csv"
        export GIT_URL="https://my-url/org/repo"
        export REVISION="abcd1234"
        export DATA_BUNDLE_REPO="quay.io/konflux-ci/tekton-catalog/data-acceptable-bundles"

        When call hack/build-acceptable-bundles.sh "test-task-bundle-list"
        The status should be success
        The path test-task-bundle-list.csv should be file
        The contents of file "test-task-bundle-list.csv" should equal "quay.io/konflux-ci/task-task1:0.1-1234@sha256:5678,quay.io/konflux-ci/task-task1:0.1
quay.io/konflux-ci/task-task2:0.1-1234@sha256:5678,quay.io/konflux-ci/task-task2:0.1"
        The stdout should include "Bundles to be added:"
        The stdout should include "quay.io/konflux-ci/task-task1:0.1"
        The stdout should include "quay.io/konflux-ci/task-task2:0.1"
    End

    It "copies to the right image locations"
        export OUTPUT_TASK_BUNDLE_LIST="test-task-bundle-list.csv"
        When call "hack/push-and-tag.sh"
        The status should be success
        The output should include "Copying from quay.io/konflux-ci/task-task1:0.1-1234@sha256:5678 to quay.io/konflux-ci/task-task1:0.1"
        The output should include "Copying from quay.io/konflux-ci/task-task2:0.1-1234@sha256:5678 to quay.io/konflux-ci/task-task2:0.1"
    End
End
