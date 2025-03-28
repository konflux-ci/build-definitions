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
#
# Test with a local cluster:
#
# - Before starting test with local cluster, launch one by `kind create
#   cluster'.  Then, install tekton pipelines
#   https://tekton.dev/docs/pipelines/install/#installation
#
# - Set IN_CLUSTER to true.

set -euo pipefail

SCRIPTDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
cd "$SCRIPTDIR/.." || exit 1
unset SCRIPTDIR

declare -r BUILD_PIPELINE_CONFIG=https://raw.githubusercontent.com/redhat-appstudio/infra-deployments/refs/heads/main/components/build-service/base/build-pipeline-config/build-pipeline-config.yaml
declare -r LABEL_TASK_VERSION=app.kubernetes.io/version

WORK_DIR=$(mktemp -d --suffix=-validate-migrations)
declare -r WORK_DIR

: "${DEFAULT_BRANCH:=main}"
declare -r DEFAULT_BRANCH

# By default, do not run with a real kubernetes cluster.
: "${IN_CLUSTER:=""}"
declare -r IN_CLUSTER

info() {
    echo "info: $*" >&2
}

error() {
    echo "error: $*" >&2
}

warning() {
    echo "warning: $*" >&2
}

format_yaml_in_python() {
    local -r filepath=$1
    python3 -c "
import sys
from ruamel.yaml import YAML
yaml = YAML()
# These settings are same as pipeline-migration-tool
yaml.preserve_quotes = True
yaml.width = 8192
yaml_file = sys.argv[1]
with open(yaml_file, 'r', encoding='utf-8') as f:
    data = yaml.load(f)
with open(yaml_file, 'w', encoding='utf-8') as f:
    yaml.dump(data, f)
" "$filepath"
}

wrapped_diff() {
    set +e
    echo "\`\`\`diff"
    diff "$@"
    status=$?
    echo "\`\`\`"
    return $status
}


prepare_pipelines() {
    local -a pl_names_in_config
    local pushed_pipelines

    mkdir -p "${WORK_DIR}/pipelines/pushed"

    # Download pushed pipeline bundles from ConfigMap
    pushed_pipelines=$(
        curl --fail -sL "$BUILD_PIPELINE_CONFIG" | yq '.data."config.yaml"' | yq '.pipelines[] | .name + " " + .bundle'
    )

    while read -r pl_name pl_bundle; do
        pl_names_in_config+=("$pl_name")
        pl_file="${WORK_DIR}/pipelines/pushed/${pl_name}.yaml"
        info "fetch pipeline $pl_name from bundle $pl_bundle -> $pl_file"
        tkn bundle list "$pl_bundle" pipeline "$pl_name" -o yaml >"$pl_file"
    done <<<"$pushed_pipelines"

    mkdir -p "${WORK_DIR}/pipelines/local"
    kubectl kustomize --output "${WORK_DIR}/pipelines/local" pipelines/

    local -r names="${pl_names_in_config[*]}"
    read -r hexdigits _ < <(sha256sum "${BASH_SOURCE[0]}")
    local -r fake_digest="sha256:${hexdigits}"
    local fake_bundle_ref=
    local task_name=
    local task_selector=

    find "${WORK_DIR}/pipelines/local" -type f -name "*.yaml" | \
        while read -r file_path; do
            if [[ ! "$names" =~ $(yq '.metadata.name' "$file_path") ]]; then
                # Drop pipelines that are not included in the config above.
                rm "$file_path"
            else
                # Replace taskRef with fake bundle reference so that the
                # .taskRef.version field will not confuse tekton.
                #
                for task_name in $(yq '(.spec.tasks[], .spec.finally[]) | .name' "$file_path"); do
                    fake_bundle_ref="{
                        \"resolver\": \"bundles\",
                        \"params\": [
                            {\"name\": \"name\", \"value\": \"${task_name}\"},
                            {\"name\": \"bundle\", \"value\": \"${fake_digest}\"},
                            {\"name\": \"kind\", \"value\": \"task\"}
                        ]
                    }"
                    task_selector="(.spec.tasks[], .spec.finally[]) | select(.name == \"${task_name}\")"
                    yq -i "(${task_selector} | .taskRef) |= ${fake_bundle_ref}" "$file_path"
                done
                format_yaml_in_python "$file_path"
            fi
        done

    return 0
}

list_preprocessed_pipelines() {
    find "${WORK_DIR}/pipelines" -type f -name "*.yaml"
}

# Check the migration does not break build pipelines.
# Only the pipelines included in the build pipeline config are checked.
# This function checks two aspects:
# - whether the migration file exits successfully or not.
# - whether the migration file modifies a pipeline. If nothing changed, it is treated a failure.
# The modified pipeline is saved into a separate file with suffix '.modified'.
check_apply_on_pipelines() {
    local -r migration_file=$1
    local -r run_log_file=$(mktemp --suffix=-migration-run-test)
    local -r prepared_pipelines=$(list_preprocessed_pipelines)
    local failed=
    local file_path=
    local updated=
    local pl_copy_file_path=
    while read -r file_path; do
        pl_copy_file_path="${file_path}.copy"
        cp "$file_path" "$pl_copy_file_path"
        info "apply migration $migration_file to pipeline $pl_copy_file_path"
        if ! bash -x "$migration_file" "$pl_copy_file_path" 2>"$run_log_file" >&2; then
            error "failed to run migration file $migration_file on pipeline $file_path:"
            cat "$run_log_file" >&2
            failed=true
        else
            info "diff to see if pipeline is modified by the migration"
            format_yaml_in_python "$pl_copy_file_path"
            if ! wrapped_diff -u "$file_path" "$pl_copy_file_path"; then
                updated=true
                mv "$pl_copy_file_path" "${file_path}.modified"
            fi
        fi
    done <<<"$prepared_pipelines"
    rm "$run_log_file"
    if [ -z "$updated" ]; then
        mapfile -t pl_names < <(
            while read -r file_path; do
                yq ".metadata.name" "$file_path"
            done <<<"$prepared_pipelines" \
                | sort | uniq
        )
        info "${FUNCNAME[0]}: migration file does not modify any of pipelines ${pl_names[*]}"
    fi
    if [ -n "$failed" ] || [ -z "$updated" ]; then
        return 1
    else
        return 0
    fi
}

# Run shellcheck against the given migration file without rules customization.
# Developers could write inline shellcheck rules.
check_pass_shellcheck() {
    local -r migration_file=$1
    if shellcheck -s bash "$migration_file"; then
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
    local -r dir_path=${migration_file%/*}  # remove file name
    echo "${dir_path%/*}"  # remove path component migrations/
}

# Check a migration file is included in a task version-specific directory.
# Each task version has its own migrations. Developers have to create
# migrations/ directory under a specific task version directory, for example
# task/buildah/0.2/migrations/.
check_migrations_is_in_task_version_specific_dir() {
    local -r migration_file=$1
    local -r parent_dir=$(resolve_migrations_parent_dir "$migration_file")
    local -r result=$(find task/*/* -type d -regex "$parent_dir" -print -quit)
    if [ -z "$result" ]; then
        info "${FUNCNAME[0]}: migrations/ directory is not created in a task version-specific directory. Current is under $parent_dir. To fix it, move it to a path like task/task-1/0.1/."
        exit 1
    fi
}

# Check that version within the migration file name must match the task version
# in task label .metadata.labels."app.kubernetes.io/version".
# When a migration file is committed, the task version must be bumped properly
# accordingly which must match the version used in migration file name.
check_version_match() {
    local -r migration_file=$1
    local -r task_dir=$(resolve_migrations_parent_dir "$migration_file")

    local task_name=${task_dir%/*}  # remove version part
    task_name=${task_name##*/}  # remove all path components before the name

    local task_version=
    local -r label=".metadata.labels.\"${LABEL_TASK_VERSION}\""

    if is_normal_task "$task_dir" "$task_name" ; then
        task_version=$(yq "$label" "${task_dir}/${task_name}.yaml")
    elif is_kustomized_task "$task_dir" "$task_name"; then
        task_version=$(kubectl kustomize "$task_dir" | yq "$label")
    else
        exit 1
    fi

    if [ "${migration_file%/*}/${task_version}.sh" == "$migration_file" ]; then
        return 0
    fi

    info "${FUNCNAME[0]}: migration file does not match the task version '${task_version}'. "
    info "Bump version in label '${LABEL_TASK_VERSION}' to match the migration."

    return 1
}

is_on_topic_branch() {
    if [ "$(git branch --show-current)" != "$DEFAULT_BRANCH" ]; then
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
    local task_dir_path  # Used as key for TASK_MIGRATIONS
    local file_list
    file_list=$(git diff --name-status "$(git merge-base HEAD "$DEFAULT_BRANCH")")
    local seen=
    while read -r status origin_path; do
        if ! is_migration_file "$origin_path"; then
            continue
        fi
        case "$status" in
            A)  # file is added
                task_dir_path=$(awk -F '/' '{ OFS = "/"; print $1, $2 }' <<<"$origin_path")
                if grep -q "^${task_dir_path}$" <<<"$seen"; then
                    error "There must be one migration file per task in a single pull request."
                    return 1
                else
                    seen="$seen
$task_dir_path"
                    echo "$origin_path"
                fi
                ;;
            D | M)
                error "It is not allowed to delete or modify existing migration file: $origin_path"
                error "Please bump task version in the label '${LABEL_TASK_VERSION}' and create a new migration file."
                exit 1
                ;;
            *)
                warning "unknown operation for status $status on file $origin_path"
                ;;
        esac
    done <<<"$file_list"
    return $?
}

K8S_TEST_NS=validate-migration-test
declare -r K8S_TEST_NS

# Check whether modified pipelines with applied migration is broken or not.
# This check requires a created cluster with tekton installed.
# An easy way to set up a local cluster is running `kind create cluster'.
check_apply_in_real_cluster() {
    if [ -z "$IN_CLUSTER" ]; then
        info "environment variable IN_CLUSTER is not set, skip ${FUNCNAME[0]}"
        return 0
    fi
    if ! kubectl get crd pipelines.tekton.dev -n tekton-pipelines >/dev/null 2>&1; then
        error "cannot find CRD pipeline.tekton.dev from cluster. Please create a cluster and install tekton."
        exit 1
    fi
    if kubectl get namespaces ${K8S_TEST_NS} >/dev/null 2>&1; then
        info "k8s namespace ${K8S_TEST_NS} exists, remove all pipelines from it."
        kubectl delete pipeline --all -n ${K8S_TEST_NS} >/dev/null
    else
        info "create k8s namespace ${K8S_TEST_NS}"
        kubectl create namespace ${K8S_TEST_NS}
    fi
    local apply_logfile
    local modified_pipeline_files
    apply_logfile=$(mktemp --suffix="-${FUNCNAME[0]}")
    modified_pipeline_files=$(find "${WORK_DIR}/pipelines" -type f -name "*.modified")
    if [ -z "$modified_pipeline_files" ]; then
        error "No modified pipeline file is found."
        error "Please check if migrations work correctly to update pipelines."
        exit 1
    fi
    while read -r pl_file; do
        info "apply pipeline with migrations in namespace ${K8S_TEST_NS}: ${pl_file}"
        if ! kubectl apply -f "$pl_file" -n ${K8S_TEST_NS} 2>"$apply_logfile" >/dev/null; then
            error "${FUNCNAME[0]}: failed to apply pipeline to cluster: $pl_file"
            cat "$apply_logfile" >&2
            rm "$apply_logfile"
            exit 1
        fi
    done <<<"${modified_pipeline_files}"
    rm "$apply_logfile"
}

main() {
    if git status --porcelain | grep -qv "^??"; then
        info "There are uncommitted changes. Please commit them and run again."
        exit 1
    fi

    if ! is_on_topic_branch; then
        info "Script must run on a topic branch rather than the main branch."
        return 1
    fi

    local output
    output="$(list_migration_files)"

    if [ -z "$output" ]; then
        info "No migration."
        exit 0
    fi

    info "prepare Konflux standard pipelines"
    prepare_pipelines

    for migration_file in $output; do
        info "check pass shellcheck"
        check_pass_shellcheck "$migration_file"

        info "check migrations/ is created in versioned-specific task directory"
        check_migrations_is_in_task_version_specific_dir "$migration_file"

        info "check migration file name matches the concrete task version in the label"
        check_version_match "$migration_file"

        info "cleanup any existing pipeline files modified previously."
        find "${WORK_DIR}/pipelines" -type f -name "*.modified" -delete

        info "check apply migrations to standard pipelines included in the build-pipeline-config"
        check_apply_on_pipelines "$migration_file"

        info "check apply pipelines with migrations into a cluster"
        check_apply_in_real_cluster
    done
}

main "$@"
