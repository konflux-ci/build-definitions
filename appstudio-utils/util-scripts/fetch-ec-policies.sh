#!/usr/bin/bash
set -euo pipefail

# Currently this is fetching directly from github. In future we
# might fetch a container image with the rego files inside it.

source $(dirname $0)/lib/fetch.sh

# Ensure there's no stale data
clear-policies

title "Fetching policy files"
git-fetch-policies

title "Policy files"
show-policies
