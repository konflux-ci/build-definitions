#!/usr/bin/bash
set -euo pipefail

#
# Download the rego files that will be used by Enterprise Contract.
#
# Currently this is fetching directly from github. In future it might
# fetch a container image or a bundle with the rego files inside it, or
# we might include the rego files in the app-studio-utils image directly,
# which would mean this script is no longer needed.
#
# The env vars POLICY_REPO and POLICY_REPO_REF can be set to override
# the defaults for what git repo and branch or sha to use.
#
# See also tasks/enterprise-contract.yaml
#
source $(dirname $0)/lib/fetch.sh

# Ensure there's no stale data
clear-policies

title "Fetching policy files"
git-fetch-policies

title "Policy files"
show-policies
