#!/bin/bash

source $(dirname $0)/common.sh

TMPF=$(mktemp /tmp/.mm.XXXXXX)
clean() { rm -f ${TMPF}; }
trap clean EXIT

# Configure the number of parallel tests running at the same time, start from 0
MAX_NUMBERS_OF_PARALLEL_TASKS=7 # => 8

# You can ignore some yaml tests by providing the TEST_YAML_IGNORES variable
# with the test name separated by a space, for example:
#
# TEST_YAML_IGNORES="kaniko s2i"
#
# will ignore the kaniko and s2i tests,
#
TEST_YAML_IGNORES=${TEST_YAML_IGNORES:-""}

# Allow ignoring some yaml tests, space separated, should be the basename of the
# test for example "s2i"
TEST_TASKRUN_IGNORES=${TEST_TASKRUN_IGNORES:-""}

# Define this variable if you want to run all tests and not just the modified one.
TEST_RUN_ALL_TESTS=${TEST_RUN_ALL_TESTS:-""}

set -ex
set -o pipefail

all_tests=$(echo task/*/*/tests)
all_stepactions=$(echo stepactions/*/*/tests)

[[ -z ${TEST_RUN_ALL_TESTS} ]] && [[ ! -z $(detect_changed_e2e_test) ]] && TEST_RUN_ALL_TESTS=1

if [[ -z ${TEST_RUN_ALL_TESTS} ]];then
    all_tests=$(detect_new_changed_resources|sort -u || true)
    [[ -z ${all_tests} ]] && {
        echo "No tests has been detected in this PR. exiting."
        success
    }
fi

#test_yaml_can_install "${all_stepactions}"
test_yaml_can_install "${all_tests}"

function test_resources {
    local cnt=0
    local resource_to_tests=""

    for runtest in $@;do
        resource_to_tests="${resource_to_tests} ${runtest}"
        if [[ ${cnt} == "${MAX_NUMBERS_OF_PARALLEL_TASKS}" ]];then
            test_resource_creation "${resource_to_tests}"
            cnt=0
            resource_to_tests=""
            continue
        fi
        cnt=$((cnt+1))
    done

    # in case if there are some remaining resources
    if [[ -n ${resource_to_tests} ]];then
        test_resource_creation "${resource_to_tests}"
    fi
}

#test_resources "${all_stepactions}"
test_resources "${all_tests}"

success