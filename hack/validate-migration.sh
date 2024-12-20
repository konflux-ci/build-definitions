#!/usr/bin/env bash

# Validate migration file introduced by a branch.
#
# This script can be run in the CI against a PR or in local from a topic branch.
# Before run, all local changes have to be committed.
#
# Network is required to execute this script.
#
# Checks are implemented as functions whose name has prefix `check_`. Each of
# them exits with status code 0 to indicate pass, otherwise exits
# script execution immediately with non-zero code.

set -euo pipefail

SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd "$SCRIPTDIR/.." || exit 1
unset SCRIPTDIR

declare -r BUILD_PIPELINE_CONFIG=https://raw.githubusercontent.com/redhat-appstudio/infra-deployments/refs/heads/main/components/build-service/base/build-pipeline-config/build-pipeline-config.yaml

WORK_DIR=$(mktemp --suffix=-validate-migrations)
declare -r WORK_DIR

declare -r DEFAULT_BRANCH=main

fail_unless_file_exists() {
    if [ ! -f "$1" ]; then
        echo "error: no such file $1" >&2
        exit 2
    fi
    return 0
}

preprocess_pipelines() {
    local -a pl_names

    mkdir -p "${WORK_DIR}/pipelines/pushed"

    # Download pushed pipeline bundles from ConfigMap
    curl -L "$BUILD_PIPELINE_CONFIG" | yq '.data."config.yaml"' | yq '.pipelines[] | .name + " " + .bundle' | \
        while read -r pl_name pl_bundle; do
            pl_names+=("$pl_name")
            tkn bundle list "$pl_bundle" pipeline "$pl_name" -o yaml \
                >"${WORK_DIR}/pipelines/pushed/${pl_name}.yaml"
        done
    
    mkdir -p "${WORK_DIR}/pipelines/local"
    oc kustomize --output "${WORK_DIR}/pipelines/local" pipelines/

    local -r pl_names_line="${pl_names[*]}"

    # Drop pipelines that are not included in the config above.
    find "${WORK_DIR}/pipelines/local" -type f -name "*.yaml" | \
        while read -r file_path; do
            if [[ "$pl_names_line" =~ $(yq '.metadata.name' "$file_path") ]]; then
                rm "$file_path"
            fi
        done

    return 0
}

list_preprocessed_pipelines() {
    find "${WORK_DIR}/pipelines" -type f -name "*.yaml"
}

# Migration script should run without errors (0 exit code) on the pre-latest default pipeline.
# after performing migration, the pipeline yaml should be valid (yaml and pipeline definition)
# Test should run on all pipelines (docker, FBC and their trusted artifacts and remote versions)
check_apply_on_pipelines() {
    local -r migration_file=$1
    fail_unless_file_exists "$migration_file"
    run_log_file=$(mktemp --suffix=-migration-run-test)
    local -r run_log_file
    local failed=
    while read -r file_path; do
        if ! bash -x "$migration_file" "$file_path" 2>"$run_log_file" >&2; then
            echo "error: failed to run migration file $migration_file on pipeline $file_path:" >&2
            cat "$run_log_file" >&2
            failed=true
        fi
    done <<<"$(list_preprocessed_pipelines)"
    rm "$run_log_file"
    if [ -n "$failed" ]; then
        return 1
    else
        return 0
    fi
}

# pass shellcheck. No customization to the rules of shellcheck. Migration
# script must pass the default set of shellcheck rules (but still possible to
# exclude inline).

# Run shellcheck against the given migration file without rules customization.
# Developers could write inline shellcheck rules.
check_pass_shellcheck() {
    local -r migration_file=$1
    if shellcheck "$migration_file"; then
        return 0
    fi
    return 1
}

# Determine if a task is a normal task. 0 returns if it is, otherwise 1 is returned.
is_normal_task() {
    local -r task_dir=$1
    local -r task_name=$2
    if [ -f "${task_dir}/${task_name}.yaml" ]; then
        return 0
    fi
    return 1
}

# Determine if a task is a kustomized task. 0 returns if it is, otherwise 1 is returned.
is_kustomized_task() {
    local -r task_dir=$1
    local -r task_name=$2
    local -r kt_config_file="$task_dir/kustomization.yaml"
    local -r task_file="${task_dir}/${task_name}.yaml"
    if [ -f "$kt_config_file" ] && [ ! -e "$task_file" ]; then
        return 0
    fi
    return 1
}

# Resolve the parent directory of given migration. For example, the given
# migration file is path/to/dir/migrations/0.1.1.sh, then function outputs
# path/to/dir. The parent directory path is output to stdout.
# Arguments: migration file path.
resolve_migrations_parent_dir() {
    local -r migration_file=$1
    local dir_path=${migration_file%/*}  # remove file name
    echo "${dir_path%/*}"  # remove path component migrations/
}

check_migrations_is_in_task_version_specific_dir() {
    local -r migration_file=$1
    parent_dir=$(resolve_migrations_parent_dir "$migration_file")
    local -r parent_dir
    local result
    result=$(find task/*/* -type d -regex "$parent_dir" -print -quit)
    if [ -z "$result" ]; then
        echo "${FUNCNAME[0]}: migrations/ directory is not created in a task version-specific directory. Current is under $dir_path. To fix it, move it to a path like task/task-1/0.1/." >&2
        exit 1
    fi
}

# Check that version within the migration file name must match the task version
# in task label .metadata.labels."app.kubernetes.io/version".
check_version_match() {
    local -r migration_file=$1
    fail_unless_file_exists "$migration_file"

    task_dir=$(resolve_migrations_parent_dir "$migration_file")
    local -r task_dir

    local task_name=${task_dir%/*}  # remove version part
    task_name=${task_name##*/}  # remove all path components before the name

    local task_version=
    local -r label='.metadata.labels."app.kubernetes.io/version"'

    if is_normal_task "$task_dir" "$task_name" ; then
        task_version=$(yq "$label" "${task_dir}/${task_name}.yaml")
    elif is_kustomized_task "$task_dir" "$task_name"; then
        task_version=$(oc kustomize "$task_dir" | yq "$label")
    else
        exit 1
    fi

    if [ "${migration_file%/*}/${task_version}.sh" == "$migration_file" ]; then
        return 0
    fi

    echo -n "${FUNCNAME[0]}: migration file does not match the task version '${task_version}'. " >&2
    echo "Bump version in label 'app.kubernetes.io/version' to match the migration."

    return 1
}

is_on_topic_branch() {
    if [ "$(git branch --show-current)" == "$DEFAULT_BRANCH" ]; then
        return 0
    else
        return 1
    fi
}

is_migration_file() {
    local -r file_path=$1
    if [[ "$file_path" =~ /migrations/[0-9.]+\.sh$ ]]; then
        return 0
    fi
    return 1
}

# Output migration file included in the branch
# The file name is output to stdout with relative path to the root of the repository.
# Generally, there should be one, but if multiple migration files are
# discovered, it will be checked later. # No argument is required. Function
# inspects changed files from current branch directly.
list_migration_files() {
    changed_files=$(git diff --name-status "$(git merge-base HEAD $DEFAULT_BRANCH)")
    local -r changed_files
    while read -r status origin_path; do
        if ! is_migration_file "$origin_path"; then
            continue
        fi
        case "$status" in
            A)  # file is added
                echo "$origin_path"
                ;;
            D | M)
                echo "It is not allowed to delete or modify existing migration file: $origin_path" >&2
                exit 1
                ;;
            *)
                echo "warning: unknown operation for status $status on file $origin_path" >&2
                ;;
        esac
    done <<<"$changed_files"
    return 0
}

# Check whether modified pipelines with applied migration is broken or not.
# This check requires a created cluster with tekton installed.
# An easy way to set up a local cluster is running `kind create cluster'.
check_apply_in_real_cluster() {
    if [ -z "$IN_CLUSTER" ]; then
        return 0
    fi
    if ! kubectl get crd pipelines.tekton.dev -n tekton-pipelines >/dev/null 2>&1; then
        echo "error: cannot find CRD pipeline.tekton.dev from cluster. Please create a cluster and install tekton." >&2
        exit 1
    fi
    if ! kubectl get namespaces validate-migration-test >/dev/null 2>&1; then
        kubectl create namespace validate-migration-test
    fi
    apply_logfile=$(mktemp --suffix="-${FUNCNAME[0]}")
    local -r apply_logfile
    while read -r pl_file; do
        if ! kubectl apply -f "$pl_file" -n validate-migration-test 2>"$apply_logfile" >/dev/null; then
            echo "${FUNCNAME[0]}: failed to apply pipeline to cluster: $pl_file" >&2
            cat "$apply_logfile" >&2
            exit 1
        fi
    done <<<"$(list_preprocessed_pipelines)"
}

main() {
    if [ -n "$(git status --porcelain)" ]; then
        echo "There are uncommitted changes. Please commit them and run again." >&2
        exit 1
    fi

    if ! is_on_topic_branch; then
        echo "Script must run on a topic branch rather than the main branch." >&2
        return 1
    fi

    local -a migrations_files
    mapfile -t migrations_files < <(list_migration_files)

    local -r n=${#migrations_files[@]}
    if [[ $n -gt 1 ]]; then
        echo "error: found $n migration files. Please ensure to include a single migration file per time." >&2
        exit 1
    fi

    preprocess_pipelines

    local -r file_path=${migrations_files[0]}
    check_pass_shellcheck "$file_path"
    check_migrations_is_in_task_version_specific_dir "$file_path"
    check_version_match "$file_path"
    check_apply_on_pipelines "$file_path"
    check_apply_in_real_cluster
}

main "$@"
