#!/usr/bin/env bash

# <TEMPLATED FILE!>
# This file comes from the templates at https://github.com/konflux-ci/task-repo-shared-ci.
# Please consider sending a PR upstream instead of editing the file directly.
# See the SHARED-CI.md document in this repo for more details.

set -euo pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
declare -r SCRIPT_DIR

error() {
    echo "error: $*" >&2
    exit 1
}

info() {
    echo "$@" >&2
}

usage() {
    local prog
    prog="$(basename "${BASH_SOURCE[0]}")"
    echo "usage: $prog -t <task name> [-v <task version>] [-w <workding directory>] [-a] [-h]

    -h   print this usage.
    -t   task name, for which the migration is created. Select a name from task/ directory. required.
    -v   task version in form major.minor, e.g. 0.2. This is the version presenting in the path to a version-specific task. If create a migration for version 0.3 of task summary, 0.3 is the version passed to this option.
    -w   alternative working directory to find out task. If omitted, this script runs from the root this repository.
    -a   add new and modified files to git index.
    -n   use new task layout. When specify this option, option -v means nothing to this script.

Examples:

    ./hack/create-task-migration.sh -t push-dockerfile

        Create a migration for the latest major.minor version under path task/push-dockerfile/major.minor/migrations/. When task has versions 0.1 and 0.2, the major.minor is 0.2.

    ./hack/create-task-migration.sh -t push-dockerfile -w /path/to/my-definitions

        Change the working directory to /path/to/my-definitions. Script will operate task from the alternative directory.

    ./hack/create-task-migration.sh -t push-dockerfile -v 0.2

        Create a migration for a task version explicitly. This is useful particularly for a new task version with a migration. Note that, the new task has to be created in advance.

    ./hack/create-task-migration.sh -t push-dockerfile -n

        Create a migration under path task/push-dockerfile/migrations/.
"
    exit 1
}

# Determine if a task is kustomized from the other one outside of the current one.
is_kustomized_task() {
    local -r task_dir=$1
    local -r kt_config_file="$task_dir/kustomization.yaml"
    if [[ ! -f "$kt_config_file" ]]; then
        return 1
    fi
    for resource in $(yq '.resources[]'); do
        real_path=$(realpath "${task_dir}/${resource}")
        if [[ ! "${real_path%/*}" =~ ^${task_dir} ]]; then
            return 0
        fi
    done
    # Most of the tasks are not kustomized
    return 1
}

get_migration_template() {
    local -r creation_time=$1
    local -r task_name=$2
    local -r task_version=$3
    echo "#!/usr/bin/env bash

set -euo pipefail

# Created for task: ${task_name}@${task_version}
# Creation time: ${creation_time}

declare -r pipeline_file=\${1:missing pipeline file}

# 1. Use yq to retrieve information from your YAML files, but
# do NOT use 'yq -i' for modification, because it may change the formatting of the YAML file for a user.
#
# 2. When selecting tasks in your yq command, target Pipeline and PipelineRun with selectors:
#   '.spec.tasks[]' and '.spec.pipelineSpec.tasks[]'
#
# 3. Use pmt-modify to make changes to the pipeline.
# Documentation: https://github.com/konflux-ci/pipeline-migration-tool?tab=readme-ov-file#to-modify-konflux-pipelines-with-modify
#
# Example: Add a parameter
#   pmt modify -f \"\$pipeline_file\" task ${task_name} add-param \"param-name\" \"param-value\"
#
# Use generic modification when a specific subcommand for a resource is not available:
#   pmt modify -f \"\$pipeline_file\" generic replace '[\"spec\", \"tasks\", 0, \"params\", 0, \"value\"]' \"new-value\"
#
#   Learn more about pmt-modify generic here:
#   https://github.com/konflux-ci/pipeline-migration-tool?tab=readme-ov-file#unsupported-resource
#
#
# migration code here...
#
# For an example, refer to the 'Task migration' section in SHARED-CI.md
"
}


create_migration() {
    local task_name=
    local task_version=
    local work_dir=
    local add_to_index=
    local opt=
    local use_new_layout=

    while getopts 't:v:w:ahn' opt; do
        case "$opt" in
            t) task_name="$OPTARG" ;;
            v) task_version="$OPTARG" ;;
            w) work_dir="$OPTARG" ;;
            a) add_to_index=true ;;
            n) use_new_layout=true ;;
            *) usage ;;
        esac
    done

    if [[ -z "$task_name" ]]; then
        error "missing task name. Select a task from from task/ directory and pass its name to -t option."
    fi

    if [[ -z "$work_dir" ]]; then
        cd "$SCRIPT_DIR/.." || exit 1
    else
        cd "$work_dir" || exit 1
    fi

    local task_dir="task/${task_name}"

    if [[ ! -e "$task_dir" ]]; then
        error "task $task_dir does not exist."
    fi

    local detected_version=

    if [[ -z "$use_new_layout" ]]; then
        if [[ -z "$task_version" ]]; then
            detected_version=$(
                find "$task_dir" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | \
                    sort -t. -k 1,1n -k 2,2n | \
                    tail -n1
            )
            if [[ -z "$detected_version" ]]; then
                error "there is no version directory under $task_dir"
            fi
            task_version="$detected_version"
        fi

        task_dir="${task_dir}/${task_version}"

        if [[ ! -e "$task_dir" ]]; then
            error "task directory does not exist: ${task_dir}"
        fi
    fi

    local -r migration_dir="${task_dir}/migrations"
    [[ -e "$migration_dir" ]] || mkdir "$migration_dir"

    if is_kustomized_task "$task_dir"; then
        info "You are creating migration for a task kustomized from the other one."
        info "Migration directory has been created: $migration_dir. "
        info "Please create the migration file manually with correct version. REMEMBER to bump task version if necessary."
        info
        info "Recommended migration script template:"
        info "$(get_migration_template "<creation time>" "$task_name" "<task version in form major.minor.patch>")"
        return 0
    fi

    declare -r task_file="${task_dir}/${task_name}.yaml"
    if [[ ! -e "$task_file" ]]; then
        error "task file $task_file does not exist."
    fi

    IFS=. read -r major minor patch < <(
        yq '.metadata.labels."app.kubernetes.io/version"' "$task_file"
    )

    if [[ -z "$use_new_layout" ]]; then
        if [[ "${major}.${minor}" != "$task_version" ]]; then
            error "version ${major}.${minor}.${patch} is not a patched version of $task_version"
        fi
    fi

    patch=$((patch+1))
    local -r new_version="${major}.${minor}.${patch}"

    sed -i "s|^\( \+app\.kubernetes\.io/version\): .\+$|\1: \"${new_version}\"|" "$task_file"

    local -r migration_file="${migration_dir}/${new_version}.sh"
    get_migration_template "$(date --iso-8601=s --utc)" "$task_name" "$new_version" >"$migration_file"
    info "Created migration $migration_file"

    if [[ "$add_to_index" == true ]]; then
        git add "$task_file" "$migration_file"
    fi
}

create_migration "$@"
