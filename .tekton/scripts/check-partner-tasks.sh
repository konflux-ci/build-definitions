#!/usr/bin/env bash

SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd "$SCRIPTDIR/../.." || exit 1

# Expected partner task directory structure:
# task/partners/<task name>/<version>/<task file>

if [ ! -e "partners/" ]; then
    echo "No partners directory exists. Skip checks against partner tasks."
    exit 0
fi

check_dir_structure() {
    issue_found=0
    for task_dir in partners/*; do
        task_name=$(basename "$task_dir")
        for version_dir in "$task_dir"/*; do
            task_version=$(basename "$version_dir")
            if ! echo "$task_version" | grep "^[0-9]\+\.[0-9]\+$" >/dev/null 2>&1; then
                echo "error: $version_dir is not a version directory. A version directory name only contains digits and dot, e.g. 0.1, 1.2"
                issue_found=1
            else
                # Ignore empty directory whatever it is a version directory or not.
                if [ -n "$(ls "$version_dir")" ]; then
                    found=
                    for yaml_file in "$version_dir"/*.yaml; do
                        task_file=$(basename "$yaml_file")
                        if [ "${task_name}.yaml" == "$task_file" ]; then
                            found=1
                            break
                        fi
                    done
                    if [ -z "$found" ]; then
                        echo "error: no task file is found under $version_dir. A task file must be named with the same task name. For example, task name is task1, then task file must have name task1.yaml"
                        issue_found=1
                    fi
                fi
            fi
        done
    done
    return $issue_found
}

check_privilege_use() {
    resultf=$(mktemp)
    check_result=$(mktemp)

    check_cases="\
allowPrivilegeEscalation:true:allowPrivilegeEscalation is not allowed to be true to request more privileges.
runAsUser:0:root(0) is not allowed to be set to securityContext.runAsUser.
privileged:true:securityContext.privileged is not allowed to be true."

    find partners/*/*/*.yaml | awk -F '/' '{ print $0, $2, $4 }' | \
    while read -r task_file task_name yaml_file; do
    if [ "${task_name}.yaml" != "$yaml_file" ]; then
        continue
    fi

    while IFS=: read -r sc_config check_value err_msg; do
        task_idx=0
        # When no securityContext config is set, yq outputs message "Error: no matches found" to stderr.
        # Redirect this message into stdout in order to suppress these potential Errors, and such error
        # messages does not match any config value obviously.
        for value in $(yq -e ".spec.steps[].securityContext.$sc_config" "$task_file" 2>&1); do
            if [ "$value" == "$check_value" ]; then
                echo "found" >>"$resultf"
                step_name=$(yq -e ".spec.steps[$task_idx].name" "$task_file")
                echo "error: in step $step_name, $err_msg" >>"$check_result"
            fi
            task_idx=$((task_idx+1))
        done
    done <<<"$check_cases"

    if [ -s "$check_result" ]; then
        echo "Task $task_file uses unexpected privileges:"
        cat "$check_result"
        echo
        echo >"$check_result"
    fi
    done

    [ -s "$resultf" ] && return 1
    return 0
}

check_task_schema() {
    resultf=$(mktemp)
    check_result=$(mktemp)
    find partners/*/*/*.yaml | awk -F '/' '{ print $0, $2, $4 }' | \
    while read -r task_file task_name yaml_file; do
        if [ "${task_name}.yaml" != "$yaml_file" ]; then
            continue
        fi

        if ! oc apply -f "$task_file" --dry-run=server >"$check_result" 2>&1; then
            echo "issue found" >>"$resultf"
            echo "Task schema validation failed: $task_file"
            cat "$check_result"
            echo
        fi

        echo >"$check_result"
    done
    [ -s "$resultf" ] && return 1
    return 0
}

exitcode=0
check_dir_structure_status=Fail
check_task_schema_status="n/a "
check_privilege_use_status="n/a "

if check_dir_structure; then
    check_dir_structure_status=Pass
    if check_task_schema; then
        check_task_schema_status=Pass
    else
        check_task_schema_status=Fail
        exitcode=$((exitcode+1))
    fi

    if check_privilege_use; then
        check_privilege_use_status=Pass
    else
        check_privilege_use_status=Fail
        exitcode=$((exitcode+1))
    fi
else
    exitcode=1
fi

echo "
|        Check         | Status |
|----------------------+--------|
| Directory structure  | $check_dir_structure_status   |
| Task YAML definition | $check_task_schema_status   |
| Privilege use        | $check_privilege_use_status   |"

exit $exitcode
