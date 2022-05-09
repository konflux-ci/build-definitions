#!/bin/bash
#
# Verifies the given test results passes the given rego policy
# usage:
#   verify-test-results-with-policy.sh <in-toto file> <output file> <passed file>
# where:
#   <test-results file> file containing the results to be verified
#   <output file>  where to store the result in JSON format
#   <passed file>  where to store the overall passing result
set -euo pipefail

test-results="$1"
output="$2"
passed="$3"

cd $(dirname $0)
source lib/fetch.sh

# TODO: If git clone fails, the task does not fail - fix that!
./fetch-ec-policies.sh

save-policy-config

title test-results
# Save the attestations for opa processing
echo -n "${test-results}" > $(json-input-file test-results)

title Violations
export OPA_QUERY=hacbs.contract.test
./check-ec-policy.sh | tee "${output}"

title "Passed?"
./ec-pass-fail.sh "${output}" | tee "${passed}"

# If strict mode is enabled, fail the script (and the task)  when the policy check fails.
# Otherwise, complete successfully.
if [[ "${STRICT_POLICY:-'1'}" == "1" ]]; then
    [[ "$(cat ${passed})" == "true" ]]
fi
