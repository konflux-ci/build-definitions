#!/bin/bash
set -o errexit -o nounset -o pipefail

# <TEMPLATED FILE!>
# This file comes from the templates at https://github.com/konflux-ci/task-repo-shared-ci.
# Please consider sending a PR upstream instead of editing the file directly.
# See the SHARED-CI.md document in this repo for more details.

# Finds the Renovate configuration file (typically renovate.json) in the repo and updates
# ignorePaths to include all the .github/ files that come from the Shared CI repository.
#
# If there is no Renovate configuration file, creates a new renovate.json.

# https://docs.renovatebot.com/configuration-options/
# We don't support json5, but let's ignore the file extension
#   .json doesn't mean it's not JSON5, and .json5 doesn't mean it's not regular JSON
#   Leave it to jq to fail if failure is unavoidable
renovate_config_paths=(
    renovate.json
    renovate.json5
    .github/renovate.json
    .github/renovate.json5
    .gitlab/renovate.json
    .gitlab/renovate.json5
    .renovaterc
    .renovaterc.json
    .renovaterc.json5
)

renovate_config_path=${renovate_config_paths[0]}
for filepath in "${renovate_config_paths[@]}"; do
    if [[ -e "$filepath" ]]; then
        renovate_config_path=$filepath
        break
    fi
done

shared_ci_files=$(
    grep -R '^# <TEMPLATED FILE!>' .github/ --files-with-matches |
    jq --raw-input | jq --slurp --compact-output
)

new_renovate_json=$(
    if [[ -s "$renovate_config_path" ]]; then
        cat "$renovate_config_path"
    else
        # $renovate_config_path empty or missing => use default config
        # https://docs.renovatebot.com/config-overview/#onboarding-config
        jq -n '{
            "$schema": "https://docs.renovatebot.com/renovate-schema.json"
        }'
    fi | jq --argjson shared_ci_files "$shared_ci_files" '
        ((.ignorePaths + $shared_ci_files) | unique) as $new_ignore_paths |
        if .ignorePaths == $new_ignore_paths then
            empty
        else
            .ignorePaths = $new_ignore_paths
        end
    '
)

if [[ -z "$new_renovate_json" ]]; then
    echo "$renovate_config_path is up to date" >&2
else
    if [[ -e "$renovate_config_path" ]]; then
        echo "updated $renovate_config_path" >&2
    else
        echo "created $renovate_config_path" >&2
    fi
    printf '%s\n' "$new_renovate_json" > "$renovate_config_path"
fi
