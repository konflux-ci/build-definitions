#!/usr/bin/env bash

check_result=$(mktemp)

# Check the OWNERS file is present for each task
find task/ -mindepth 1 -maxdepth 1 -type d | \
    while read -r task_dir; do
        owners_file="$task_dir/OWNERS"
        if [ ! -e "$owners_file" ]; then
            echo "error: missing owners file $owners_file" >>"$check_result"
            continue
        fi
        approvers=$(yq '.approvers[]' $owners_file)
        reviewers=$(yq '.reviwers[]' $owners_file)
        if [ -z "$approvers" ] && [ -z "$reviewers" ]; then
            echo "error: $task_dir/OWNERS don't have atleast 1 approver and 1 reviewer" >>"$check_result"
        fi
    done

if [ -s "$check_result" ]; then
    cat "$check_result"
    echo "Please add OWNERS file with atleast 1 approver and 1 reviewer"
    exit 1
fi

