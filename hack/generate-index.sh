#!/bin/bash
# Build an asciidocs index of all tasks defined in this repo.

set -e -o pipefail

VCS_URL=https://github.com/konflux-ci/build-definitions

# local dev build script
SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
WORKDIR=$(mktemp -d --suffix "-$(basename "${BASH_SOURCE[0]}" .sh)")

cat << EOF > "$WORKDIR/tasks.adoc"
[cols="1,1,1,1,1,1"]
|===
|Name|Description|README|Usage|Migration|Troubleshooting
EOF

# Build tasks
(
cd "$SCRIPTDIR/.."
find task/*/*/ -maxdepth 0 -type d | awk -F '/' '{ print $0, $2, $3 }' | \
while read -r task_dir task_name task_version
do
    url="${VCS_URL}/tree/main/${task_dir}"

    echo >> "$WORKDIR/tasks.adoc"
    echo "|${url}[$task_name @ $task_version]" >> "$WORKDIR/tasks.adoc"

    if [ -f "${task_dir}/${task_name}.yaml" ]; then
        description=$(yq '.spec.description | split("\n") | .[0]' "$task_dir/$task_name.yaml")
    else
        description=
    fi
    echo "|$description" >> "$WORKDIR/tasks.adoc"

    for document in README.md USAGE.md MIGRATION.md TROUBLESHOOTING.md; do
        if [ -f "${task_dir}/${document}" ]; then
            echo "|${url}${document}[${document}]" >> "$WORKDIR/tasks.adoc"
        else
            echo "|" >> "$WORKDIR/tasks.adoc"
        fi
    done
done
)
echo "|===" >> "$WORKDIR/tasks.adoc"

echo "$WORKDIR/tasks.adoc"
