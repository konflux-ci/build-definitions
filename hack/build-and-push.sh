#!/bin/bash

# There are two major types of tasks in build-definitions:
#
# - Normal tasks, which are written as Tekton Task resource.
#
# - kustomized tasks, which are customized by kustomization based on normal
#   tasks. kustomized tasks can be customized either based on another normal
#   task, e.g. task buildah-24gb is based on task buildah. This type of
#   kustomized task inherits the interface without change. Or based on itself,
#   e.g. task inspect-image.
#
# Task are built and pushed to the registry as Tekton task bundles. There are
# two kinds of tags in a single task bundle repository.
#
# - floating tag: this is the version defined in the task directory path,
#   e.g. 0.1 included in path task/buildah/0.1. It always points to
#   the newest pushed bundle of the version.
#
# - fixed tag: it is in form <task version>-<identifier> to identifies a
#   single bundle. For normal tasks, the identifier is the git commit hash
#   where the task gets update. For the kustomized tasks, the identifier is
#   calculated from the task YAML content generated by kustomization.
#
# Configuration
#
# - ENABLE_CACHE: enable a local cache to reduce the number of skopeo-inspect
#   runs for fetching image digest. This is useful for local tesing particually.
#   Do not use it in the CI.
#
# - TEST_TASKS: script builds and pushes tasks only listed in this value. For
#   testing purpose only. It is useful for checking the result task bundles
#   generally. Note that, if used, the result pipelines are broken.

set -e -o pipefail

export VCS_URL=https://github.com/konflux-ci/build-definitions
VCS_REF=$(git rev-parse HEAD)
export VCS_REF

export ARTIFACT_TYPE_TEXT_XSHELLSCRIPT="text/x-shellscript"
export ANNOTATION_TASK_MIGRATION="dev.konflux-ci.task.migration"
export TEST_TASKS=${TEST_TASKS:-""}

AUTH_JSON=
if [ -e "$XDG_RUNTIME_DIR/containers/auth.json" ]; then
    AUTH_JSON="$XDG_RUNTIME_DIR/containers/auth.json"
elif [ -e "$HOME/.docker/config.json" ]; then
    AUTH_JSON="$HOME/.docker/config.json"
else
    echo "warning: cannot find registry authentication file." 1>&2
fi
export AUTH_JSON

function is_official_repo() {
    # match e.g.
    #   redhat-appstudio-tekton-catalog
    #   quay.io/redhat-appstudio-tekton-catalog/.*
    #   konflux-ci/tekton-catalog
    #   quay.io/konflux-ci/tekton-catalog/.*
    grep -Eq '^(quay\.io/)?(redhat-appstudio-tekton-catalog|konflux-ci/tekton-catalog)(/.*)?$' <<< "$1"
}

function should_skip_repo() {
    local -r quay_namespace="$1"
    local -r repo_name="$2"

    # only skip repos in the redhat-appstudio-tekton-catalog namespace
    if [ "$quay_namespace" != redhat-appstudio-tekton-catalog ]; then
        return 1
    fi

    local http_code
    http_code=$(
        curl -I -s -L -w "%{http_code}\n" -o /dev/null "https://quay.io/v2/${quay_namespace}/${repo_name}/tags/list"
    )

    # and only skip them if they don't already exist
    [ "$http_code" != "200" ]
}

# local dev build script
SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd "$SCRIPTDIR/.." || exit 1
unset SCRIPTDIR

WORKDIR=$(mktemp -d --suffix "-$(basename "${BASH_SOURCE[0]}" .sh)")
export WORKDIR

retry() {
    local status
    local retry=0
    local -r interval=${RETRY_INTERVAL:-5}
    local -r max_retries=5
    while true; do
        "$@" && break
        status=$?
        ((retry+=1))
        if [ $retry -gt $max_retries ]; then
            return $status
        fi
        echo "info: Waiting for a while, then retry ..." 1>&2
        sleep "$interval"
    done
}

# Helper function to record the image reference from the output of
# the "tkn bundle push" command into a given file.
# Params:
#   1. Image reference including the tag
#   2. Output file
# Returns the piped in standard input followed by a line containing the image
# reference including tag and digest
function save_ref() {
    local output
    output="$(< /dev/stdin)"
    echo "${output}"
    local digest
    digest="$(echo "${output}" | grep -Po '@\K(sha256:[a-f0-9]*)')"

    local tagRef
    tagRef="$1"
    local refFile
    refFile="$2"
    echo "${tagRef}@${digest}" >> "${refFile}"
    echo "Created:"
    echo "${tagRef}@${digest}"
}

function escape_tkn_bundle_arg() {
    # the arguments to `tkn bundle --annotate` need to be escaped in a curious way
    # see https://github.com/tektoncd/cli/issues/2402 for details

    local arg=$1
    # replace single double-quotes with double double-quotes (this escapes the double-quotes)
    local escaped_arg=${arg//\"/\"\"}
    # wrap the whole thing in double-quotes (this escapes commas)
    printf '"%s"' "$escaped_arg"
}

# NOTE: the "namespace" here can be ${organization}/${subpath}, e.g. konflux-ci/tekton-catalog
# That will result in bundles being pushed to quay.io/konflux-ci/tekton-catalog/* repos
if [ -z "$QUAY_NAMESPACE" ]; then
    echo "QUAY_NAMESPACE is not set, skip this build."
    exit 0
fi
if [ -z "$BUILD_TAG" ]; then
    if is_official_repo "$QUAY_NAMESPACE"; then
        echo "'${QUAY_NAMESPACE}' repo is used, define BUILD_TAG"
        exit 1
    else
        # At the step of converting tasks to Tekton catalog, this is only
        # applied to non-task resources.
        BUILD_TAG=$(date +"%Y-%m-%d-%H%M%S")
        echo "BUILD_TAG is not defined, using $BUILD_TAG"
    fi
fi

# Specify TEST_REPO_NAME env var if you want to push all images to a single quay repository
# (This method is used in PR testing)
: "${TEST_REPO_NAME:=}"

export TEST_REPO_NAME

APPSTUDIO_UTILS_IMG="quay.io/$QUAY_NAMESPACE/${TEST_REPO_NAME:-appstudio-utils}:${TEST_REPO_NAME:+appstudio-utils-}$BUILD_TAG"

OUTPUT_TASK_BUNDLE_LIST="${OUTPUT_TASK_BUNDLE_LIST-task-bundle-list}"
OUTPUT_PIPELINE_BUNDLE_LIST="${OUTPUT_PIPELINE_BUNDLE_LIST-pipeline-bundle-list}"
rm -f "${OUTPUT_TASK_BUNDLE_LIST}" "${OUTPUT_PIPELINE_BUNDLE_LIST}"

export OUTPUT_TASK_BUNDLE_LIST OUTPUT_PIPELINE_BUNDLE_LIST

# Build appstudio-utils image
if [ "$SKIP_BUILD" == "" ]; then
    echo "Using $QUAY_NAMESPACE to push results "
    docker build -t "$APPSTUDIO_UTILS_IMG" "appstudio-utils/"
    docker push "$APPSTUDIO_UTILS_IMG"

    # This isn't needed during PR testing
    if [[ "$BUILD_TAG" != "latest" && -z "$TEST_REPO_NAME" ]]; then
        # tag with latest
        IMAGE_NAME="${APPSTUDIO_UTILS_IMG%:*}:latest"
        docker tag "$APPSTUDIO_UTILS_IMG" "$IMAGE_NAME"
        docker push "$IMAGE_NAME"
    fi

fi

GENERATED_PIPELINES_DIR=$(mktemp -d -p "$WORKDIR" pipelines.XXXXXXXX)
declare -r GENERATED_PIPELINES_DIR
oc kustomize --output "$GENERATED_PIPELINES_DIR" pipelines/

# Generate YAML files separately since pipelines for core services have same .metadata.name.
CORE_SERVICES_PIPELINES_DIR=$(mktemp -d -p "$WORKDIR" core-services-pipelines.XXXXXXXX)
declare -r CORE_SERVICES_PIPELINES_DIR
oc kustomize --output "$CORE_SERVICES_PIPELINES_DIR" pipelines/core-services/


inject_bundle_ref_to_pipelines() {
    local -r task_name=$1
    local -r task_version=$2
    local -r task_bundle_with_digest=$3
    local -r bundle_ref="{
        \"resolver\": \"bundles\",
        \"params\": [
            {\"name\": \"name\", \"value\": \"${task_name}\"},
            {\"name\": \"bundle\", \"value\": \"${task_bundle_with_digest}\"},
            {\"name\": \"kind\", \"value\": \"task\"}
        ]
    }"
    local -r task_selector="select(.name == \"${task_name}\" and .version == \"${task_version}\")"
    find "$GENERATED_PIPELINES_DIR" "$CORE_SERVICES_PIPELINES_DIR" -maxdepth 1 -type f -name '*.yaml' | \
        while read -r pipeline_file; do
            yq e "(.spec.tasks[].taskRef | ${task_selector}) |= ${bundle_ref}" -i "${pipeline_file}"
            yq e "(.spec.finally[].taskRef | ${task_selector}) |= ${bundle_ref}" -i "${pipeline_file}"
        done
}

# Get task version from task definition rather than the version in the directory path.
# Arguments: task_file
# The version is output to stdout.
get_concrete_task_version() {
    local -r task_file=$1
    # Ensure an empty string is output rather than string "null" if the version label is not present
    yq '.metadata.labels."app.kubernetes.io/version"' "$task_file" | sed '/null/d' | tr -d '[:space:]'
}

# Build and push a task as a Tekton bundle, that is tagged a floating tag and a fixed tag.
# The task bundle reference with digest is output to stdout in the last line,
# that is extracted from tkn-bundle-push.
build_push_task() {
    local -r task_dir=$1
    local -r prepared_task_file=$2
    local -r task_bundle=$3
    local -r task_file_sha=$4
    local -r has_migration=$5

    local -r task_description=$(yq e '.spec.description' "$prepared_task_file" | head -n 1)

    local -a ANNOTATIONS=()
    ANNOTATIONS+=("org.opencontainers.image.source=${VCS_URL}")
    ANNOTATIONS+=("org.opencontainers.image.revision=${VCS_REF}")
    ANNOTATIONS+=("org.opencontainers.image.url=${VCS_URL}/tree/${VCS_REF}/${task_dir}")
    ANNOTATIONS+=("org.opencontainers.image.version=$(get_concrete_task_version "$prepared_task_file")")
    # yq will return null if the element is missing.
    if [[ "${task_description}" != "null" ]]; then
        ANNOTATIONS+=("org.opencontainers.image.description=${task_description}")
    fi
    if [ -f "${task_dir}/README.md" ]; then
        ANNOTATIONS+=("org.opencontainers.image.documentation=${VCS_URL}/tree/${VCS_REF}/${task_dir}/README.md")
    fi
    if [ -f "${task_dir}/TROUBLESHOOTING.md" ]; then
        ANNOTATIONS+=("dev.tekton.docs.troubleshooting=${VCS_URL}/tree/${VCS_REF}/${task_dir}/TROUBLESHOOTING.md")
    fi
    if [ -f "${task_dir}/USAGE.md" ]; then
        ANNOTATIONS+=("dev.tekton.docs.usage=${VCS_URL}/tree/${VCS_REF}/${task_dir}/USAGE.md")
    fi
    if [ "$has_migration" == "true" ]; then
        ANNOTATIONS+=("dev.konflux-ci.task.migration=true")
    fi

    local -a ANNOTATION_FLAGS=()
    for annotation in "${ANNOTATIONS[@]}"; do
        ANNOTATION_FLAGS+=("--annotate" "$(escape_tkn_bundle_arg "$annotation")")
    done

    retry tkn bundle push "${ANNOTATION_FLAGS[@]}" -f "$prepared_task_file" "$task_bundle" \
        | save_ref "$task_bundle" "$OUTPUT_TASK_BUNDLE_LIST"

    # copy task to new tag pointing to commit where the file was changed lastly, so that image persists
    # even when original tag is updated
    skopeo copy "docker://${task_bundle}" "docker://${task_bundle}-${task_file_sha}"
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

# Generates task bundle with tag. The result bundle reference can be configured
# by environment variable TEST_REPO_NAME for testing purpose.
# Arguments: task_name, task_version
# Task bundle reference is output to stdout.
generate_tagged_task_bundle() {
    local -r task_name=$1 task_version=$2
    local -r repository=${TEST_REPO_NAME:-task-${task_name}}
    local -r tag=${TEST_REPO_NAME:+${task_name}-}${task_version}
    echo "quay.io/${QUAY_NAMESPACE}/${repository}:${tag}"
}

# Generate build data for a normal task. The data is output to stdout as
# space-separated fields in a single line.
# Arguments: task_dir, task_name, task_version
generate_normal_task_build_data() {
    local -r task_dir=$1 task_name=$2 task_version=$3
    local -r task_file="${task_dir}/${task_name}.yaml"
    local -r prepared_task_file="${WORKDIR}/${task_name}-${task_version}.yaml"
    cp "$task_file" "$prepared_task_file"
    local -r task_file_sha=$(git log -n 1 --pretty=format:%H -- "$task_file")
    local -r task_bundle=$(generate_tagged_task_bundle "$task_name" "$task_version")
    echo "$prepared_task_file $task_file_sha $task_bundle"
}

# Generate build data for a normal task. The data is output to stdout as
# space-separated fields in a single line.
# Arguments: task_dir, task_name, task_version
generate_kustomized_task_build_data() {
    local -r task_dir=$1 task_name=$2 task_version=$3
    local -r task_file="$task_dir/$task_name.yaml"
    local -r prepared_task_file="${WORKDIR}/${task_name}-${task_version}.yaml"
    oc kustomize "$task_dir" >"$prepared_task_file"
    local -r task_file_sha=$(sha256sum "$prepared_task_file" | awk '{print $1}')
    local -r task_bundle=$(generate_tagged_task_bundle "$task_name" "$task_version")
    echo "$prepared_task_file $task_file_sha $task_bundle"
}

declare -r ENABLE_CACHE=${ENABLE_CACHE:-""}
CACHE_FILE=

if [ -n "$ENABLE_CACHE" ]; then
    CACHE_FILE="/tmp/build-definitions-build-and-push.cache"
    declare -r CACHE_FILE
fi

cache_get() {
    local -r key=$1
    local value=
    if [ -n "$ENABLE_CACHE" ]; then
        value=$(awk -v key="$key" '$1 == key { print $2 }' <"$CACHE_FILE")
    fi
    echo "$value"
}

cache_set() {
    local -r key=$1 value=$2
    if [ -n "$ENABLE_CACHE" ]; then
        echo "${key} ${value}" >>"$CACHE_FILE"
    fi
}

# Fetch image digest.
# Arguments: image
# The digest is output to stdout.
fetch_image_digest() {
    local -r image=$1
    local digest=
    digest=$(cache_get "$image")
    if [ -z "$digest" ]; then
        digest=$(skopeo inspect --no-tags --format='{{.Digest}}' "docker://${image}" 2>/dev/null)
        if [ -n "$digest" ]; then
            cache_set "$image" "$digest"
        fi
    fi
    echo "$digest"
}

# Attach migration file to given task bundle.
# Arguments: task_dir, concrete_task_version, task_bundle
attach_migration_file() {
    local -r task_dir=$1
    local -r concrete_task_version=$2
    local -r task_bundle=$3
    local -r migration_file=$4

    # Check if task bundle has an attached migration file.
    local filename
    local found=
    local artifact_refs

    # List attached artifacts, that have specific artifact type and annotation.
    # Then, find out the migration artifact.
    #
    # Minimum version oras 1.2.0 is required for option --format
    artifact_refs=$(
        retry oras discover "$task_bundle" --artifact-type "$ARTIFACT_TYPE_TEXT_XSHELLSCRIPT" --format json | \
        jq -r "
            .manifests[]
            | select(.annotations.\"${ANNOTATION_TASK_MIGRATION}\" == \"true\")
            | .reference"
    )
    while read -r artifact_ref; do
        if [ -z "$artifact_ref" ]; then
            continue
        fi
        filename=$(
            retry oras pull --format json "$artifact_ref" | jq -r "
                .files[]
                | select(.annotations.\"org.opencontainers.image.title\" == \"${concrete_task_version}.sh\")
                | .annotations.\"org.opencontainers.image.title\"
                "
        )

        if [ -n "$filename" ]; then
            if diff "$filename" "$migration_file" >/dev/null; then
                found=true
                break
            else
                echo "error: task bundle $task_bundle has migration artifact $artifact_ref, but the migration content is different: $filename" 1>&2
                exit 1
            fi
        fi
    done <<<"$artifact_refs"

    if [ -n "$found" ]; then
        return 0
    fi

    (
        cd "${migration_file%/*}"
        retry oras attach \
            --registry-config "$AUTH_JSON" \
            --artifact-type "$ARTIFACT_TYPE_TEXT_XSHELLSCRIPT" \
            --annotation "$ANNOTATION_TASK_MIGRATION=true" \
            "$task_bundle" "${migration_file##*/}"
    )

    echo
    echo "Attached migration file ${migration_file} to ${task_bundle}"

    return 0
}

build_push_single_task() {
    local -r data_line=$1
    # read from input data line
    local task_dir task_name task_version

    local build_data
    local concrete_task_version
    local task_bundle_with_digest
    local migration_file
    local prepared_task_file
    local task_file_sha
    local task_bundle
    local output
    local has_migration

    read -r task_dir task_name task_version <<<"$data_line"

    echo "info: build and push task $task_dir" 1>&2

    if is_normal_task "$task_dir" "$task_name";  then
        build_data=$(generate_normal_task_build_data "$task_dir" "$task_name" "$task_version")
    elif is_kustomized_task "$task_dir" "$task_name";  then
        build_data=$(generate_kustomized_task_build_data "$task_dir" "$task_name" "$task_version")
    else
        echo "warning: skip handling task $task_dir since it does not follow a known task definition structure." 1>&2
        return
    fi

    read -r prepared_task_file task_file_sha task_bundle <<<"$build_data"
    digest=$(fetch_image_digest "${task_bundle}-${task_file_sha}")

    concrete_task_version=$(get_concrete_task_version "$prepared_task_file")
    migration_file="${task_dir}/migrations/${concrete_task_version}.sh"

    has_migration=false
    if [ -f "$migration_file" ]; then
        has_migration=true
    fi

    if [ -n "$digest" ]; then
        task_bundle_with_digest=${task_bundle}@${digest}
        echo "info: use existing $task_bundle_with_digest" 1>&2
    else
        echo "info: push new bundle $task_bundle" 1>&2

        output=$(build_push_task "$task_dir" "$prepared_task_file" "$task_bundle" "$task_file_sha" "$has_migration")
        echo "$output" >&2
        echo

        task_bundle_with_digest=$(grep -m 1 "^Pushed Tekton Bundle to" <<<"$output" 2>/dev/null)
        task_bundle_with_digest=${task_bundle_with_digest##* }
        cache_set "${task_bundle}-${task_file_sha}" "${task_bundle_with_digest#*@}"
    fi

    if [ "$has_migration" == "true" ]; then
        attach_migration_file "$task_dir" "$concrete_task_version" "$task_bundle_with_digest" "$migration_file"
    fi

    real_task_name=$(yq e '.metadata.name' "$prepared_task_file")
    echo "$real_task_name $task_version $task_bundle_with_digest" >>/tmp/task_bundles_data
}

export -f \
    build_push_single_task \
    build_push_task \
    cache_get \
    cache_set \
    escape_tkn_bundle_arg \
    fetch_image_digest \
    generate_normal_task_build_data \
    generate_tagged_task_bundle \
    get_concrete_task_version \
    is_kustomized_task \
    is_normal_task \
    is_official_repo \
    retry \
    save_ref \
    attach_migration_file

build_push_tasks() {
    touch /tmp/task_bundles_data

    find task/*/* -maxdepth 0 -type d | awk -F '/' '{ print $0, $2, $3 }' | \
    while read -r task_dir task_name task_version
    do
        if [ -n "$TEST_TASKS" ] && echo "$TEST_TASKS" | grep -qv "$task_name" 2>/dev/null; then
            continue
        fi

        if should_skip_repo "$QUAY_NAMESPACE" "task-${task_name}"; then
            echo "NOTE: not pushing task-$task_name:$task_version to $QUAY_NAMESPACE; the repo does not exist and $QUAY_NAMESPACE is deprecated" >&2
            continue
        fi

        echo "$task_dir $task_name $task_version"
    done | \
    parallel -j 10 build_push_single_task
}

inject_task_bundles_into_pipeilnes() {
    # version placeholder is removed naturally by the substitution.
    while read -r real_task_name task_version task_bundle_with_digest
    do
        echo "info: inject task bundle to pipelines $task_bundle_with_digest" 1>&2
        inject_bundle_ref_to_pipelines "$real_task_name" "$task_version" "$task_bundle_with_digest"
    done </tmp/task_bundles_data
}

echo "start build and push tasks" >&2
build_push_tasks

echo "inject task bundles into pipelines" >&2
inject_task_bundles_into_pipeilnes

# Used for build-definitions pull request CI only
if [ -n "$ENABLE_SOURCE_BUILD" ]; then
    for pipeline_yaml in "$GENERATED_PIPELINES_DIR"/*.yaml; do
        yq e '(.spec.params[] | select(.name == "build-source-image") | .default) = "true"' -i "$pipeline_yaml"
    done
fi

if [ "$QUAY_NAMESPACE" == redhat-appstudio-tekton-catalog ]; then
    echo "NOTE: not pushing any pipelines to $QUAY_NAMESPACE; the namespace is deprecated"
    exit 0
fi

build_push_pipeline() {
    local -r pipeline_yaml=$1

    pipeline_name=$(yq e '.metadata.name' "$pipeline_yaml")
    pipeline_description=$(yq e '.spec.description' "$pipeline_yaml" | head -n 1)
    pipeline_dir="pipelines/${pipeline_name}/"
    core_services_ci=$(yq e '.metadata.annotations."appstudio.openshift.io/core-services-ci" // ""' "$pipeline_yaml")
    if [ "$core_services_ci" == "1" ]; then
        pipeline_name="core-services-${pipeline_name}"
        BUILD_TAG=latest
    fi

    repository=${TEST_REPO_NAME:-pipeline-${pipeline_name}}
    tag=${TEST_REPO_NAME:+${pipeline_name}-}$BUILD_TAG
    pipeline_bundle=quay.io/${QUAY_NAMESPACE}/${repository}:${tag}

    ANNOTATIONS=()
    ANNOTATIONS+=("org.opencontainers.image.source=${VCS_URL}")
    ANNOTATIONS+=("org.opencontainers.image.revision=${VCS_REF}")
    ANNOTATIONS+=("org.opencontainers.image.url=${VCS_URL}/tree/${VCS_REF}/${pipeline_dir}")
    # yq will return null if the element is missing.
    if [[ "${pipeline_description}" != "null" ]]; then
        ANNOTATIONS+=("org.opencontainers.image.description=${pipeline_description}")
    fi
    if [ -f "${pipeline_dir}README.md" ]; then
        ANNOTATIONS+=("org.opencontainers.image.documentation=${VCS_URL}/tree/${VCS_REF}/${pipeline_dir}README.md")
    fi
    if [ -f "${pipeline_dir}/TROUBLESHOOTING.md" ]; then
        ANNOTATIONS+=("dev.tekton.docs.troubleshooting=${VCS_URL}/tree/${VCS_REF}/${pipeline_dir}TROUBLESHOOTING.md")
    fi
    if [ -f "${pipeline_dir}/USAGE.md" ]; then
        ANNOTATIONS+=("dev.tekton.docs.usage=${VCS_URL}/tree/${VCS_REF}/${pipeline_dir}USAGE.md")
    fi

    ANNOTATION_FLAGS=()
    for annotation in "${ANNOTATIONS[@]}"; do
        ANNOTATION_FLAGS+=("--annotate" "$(escape_tkn_bundle_arg "$annotation")")
    done

    retry tkn bundle push "${ANNOTATION_FLAGS[@]}" "$pipeline_bundle" -f "${pipeline_yaml}" | \
        save_ref "$pipeline_bundle" "$OUTPUT_PIPELINE_BUNDLE_LIST"

    if [ "$pipeline_name" == "docker-build" ]; then
        echo "$pipeline_bundle" >/tmp/docker-build-pipeline-bundle
    fi
    if [ "$pipeline_name" == "docker-build-oci-ta" ]; then
        echo "$pipeline_bundle" >/tmp/docker-build-oci-ta-pipeline-bundle
    fi
    if [ "$pipeline_name" == "docker-build-multi-platform-oci-ta" ]; then
        echo "$pipeline_bundle" >/tmp/docker-build-multi-platform-oci-ta-pipeline-bundle
    fi
    if [ "$pipeline_name" == "fbc-builder" ]; then
        echo "$pipeline_bundle" >/tmp/fbc-builder-pipeline-bundle
    fi

    if [ "$SKIP_DEVEL_TAG" == "" ] && is_official_repo "$QUAY_NAMESPACE" && [ -z "$TEST_REPO_NAME" ]; then
        NEW_TAG="${pipeline_bundle%:*}:devel"
        skopeo copy "docker://${pipeline_bundle}" "docker://${NEW_TAG}"
    fi
}

export -f build_push_pipeline

# Build Pipeline bundle with pipelines pointing to newly built task bundles
find "$GENERATED_PIPELINES_DIR"/*.yaml "$CORE_SERVICES_PIPELINES_DIR"/*.yaml | parallel -j 5 build_push_pipeline

if [ "$SKIP_INSTALL" == "" ]; then
    rm -f bundle_values.env
    {
        echo "export CUSTOM_DOCKER_BUILD_PIPELINE_BUNDLE=$(cat /tmp/docker-build-pipeline-bundle)"
        echo "export CUSTOM_DOCKER_BUILD_OCI_TA_PIPELINE_BUNDLE=$(cat /tmp/docker-build-oci-ta-pipeline-bundle)"
        echo "export CUSTOM_DOCKER_BUILD_MULTI_PLATFORM_OCI_TA_PIPELINE_BUNDLE=$(cat /tmp/docker-build-multi-platform-oci-ta-pipeline-bundle)"
        echo "export CUSTOM_FBC_BUILDER_PIPELINE_BUNDLE=$(cat /tmp/fbc-builder-pipeline-bundle)"
    } >bundle_values.env
fi


# vim: set et sw=4 ts=4:
