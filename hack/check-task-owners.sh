#!/usr/bin/env bash
set -o errexit -o nounset -o pipefail

shopt -s nullglob

codeowners_to_gitignore() {
    # drop comments and the root '*' pattern, extract the pattern from each line
    awk '/^[^#]/ && !/^\*\s/ { print $1 }' "$1"
}

temp_gitignore=$(mktemp --tmpdir "codeowners-gitignore.XXXX")
trap 'rm "$temp_gitignore"' EXIT
codeowners_to_gitignore CODEOWNERS > "$temp_gitignore"

important_dirs=$(
    for f in task/* stepactions/*; do
        if [[ -d "$f" ]]; then
            echo "$f"
        fi
    done | sort
)

codeowned_dirs=$(
    # CODEOWNERS is roughly a .gitignore file, so check which dirs are "ignored" by CODEOWNERS
    echo "$important_dirs" |
    git -c "core.excludesFile=$temp_gitignore" check-ignore --no-index --stdin |
    sort
)

missing_owners=$(comm -23 <(echo "$important_dirs") <(echo "$codeowned_dirs"))

if [[ -n "$missing_owners" ]]; then
    echo "Missing CODEOWNERS:" >&2
    # shellcheck disable=SC2001 # can't use ${variable//search/replace} instead
    sed 's/^/  /' <<< "$missing_owners" >&2
    exit 1
fi
