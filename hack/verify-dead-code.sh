#!/usr/bin/env bash

# Check that a branch does not modify dead code:
#  -> files under archived-tasks/
#  -> YAML tasks whose expires on annotation is in the past
#
# See also .github/workflows/verify-dead-code.yaml

set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.." || exit 1

command -v yq &> /dev/null || { echo "Please install yq to run this tool"; exit 1; }

emit() {
    local kind="$1" file="$2" msg="$3"
    if [[ "${GITHUB_ACTIONS:-false}" == "true" ]]; then
        printf "::%s file=%s,line=1,col=0::%s\n" "$kind" "$file" "$msg"
    else
        printf "%s: \033[1m%s\033[0m %s\n" "${kind@U}" "$file" "$msg"
    fi
}

# GNU date uses -d, BSD/macOS date uses -jf
if date --version >/dev/null 2>&1; then
    date_to_epoch() { date -d "$1" +%s; }
else
    date_to_epoch() { date -jf "%Y-%m-%dT%H:%M:%SZ" "$1" +%s; }
fi

BASE_REF="origin/${GITHUB_BASE_REF:-${DEFAULT_BRANCH:-main}}"
if ! MERGE_BASE=$(git merge-base "$BASE_REF" HEAD 2>/dev/null); then
    echo "Could not determine merge base with $BASE_REF, try 'git fetch origin'" >&2
    exit 1
fi

mapfile -t changed < <(git diff --diff-filter=AM --name-only "$MERGE_BASE" --)
if [[ ${#changed[@]} -eq 0 ]]; then
    echo "No added or modified files detected."
    exit 0
fi

today_epoch=$(date +%s)
errors=0

for file in "${changed[@]}"; do
    # archived tasks must not be touched
    if [[ "$file" == archived-tasks/* ]]; then
        emit error "$file" "modifies archived file"
        errors=$((errors + 1))
        continue
    fi

    # only look at YAML files for expiry check
    case "$file" in
        *.yaml|*.yml) ;;
        *) continue ;;
    esac
    [[ -f "$file" ]] || continue

    expires_on=$(yq '.metadata.annotations["build.appstudio.redhat.com/expires-on"] // ""' "$file" 2>/dev/null) || continue
    [[ -n "$expires_on" && "$expires_on" != "null" ]] || continue

    expires_epoch=$(date_to_epoch "$expires_on" 2>/dev/null) || {
        emit warning "$file" "could not parse expires-on: $expires_on"
        continue
    }

    if (( expires_epoch < today_epoch )); then
        emit error "$file" "task expired on $expires_on"
        errors=$((errors + 1))
    fi
done

if (( errors > 0 )); then
    echo "FAILED: $errors dead code violation(s). Revert changes to the files listed above." >&2
    exit 1
fi
echo "No dead code modifications found (${#changed[@]} file(s) checked)."
