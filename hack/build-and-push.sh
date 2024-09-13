#!/bin/bash

set -e -o pipefail

VCS_URL=https://github.com/konflux-ci/build-definitions
VCS_REF=$(git rev-parse HEAD)

function is_official_repo() {
    # match e.g.
    #   redhat-appstudio-tekton-catalog
    #   quay.io/redhat-appstudio-tekton-catalog/.*
    #   konflux-ci/tekton-catalog
    #   quay.io/konflux-ci/tekton-catalog/.*
    grep -Eq '^(quay\.io/)?(redhat-appstudio-tekton-catalog|konflux-ci/tekton-catalog)(/.*)?$' <<< "$1"
}

# local dev build script
SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
WORKDIR=$(mktemp -d --suffix "-$(basename "${BASH_SOURCE[0]}" .sh)")

tkn_bundle_push() {
    local status
    local retry=0
    local -r interval=${RETRY_INTERVAL:-5}
    local -r max_retries=5
    while true; do
        tkn bundle push "$@" && break
        status=$?
        ((retry+=1))
        if [ $retry -gt $max_retries ]; then
            return $status
        fi
        echo "Waiting for a while, then retry the tkn bundle push ..."
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

APPSTUDIO_UTILS_IMG="quay.io/$QUAY_NAMESPACE/${TEST_REPO_NAME:-appstudio-utils}:${TEST_REPO_NAME:+appstudio-utils-}$BUILD_TAG"

OUTPUT_TASK_BUNDLE_LIST="${OUTPUT_TASK_BUNDLE_LIST-${SCRIPTDIR}/../task-bundle-list}"
OUTPUT_PIPELINE_BUNDLE_LIST="${OUTPUT_PIPELINE_BUNDLE_LIST-${SCRIPTDIR}/../pipeline-bundle-list}"
rm -f "${OUTPUT_TASK_BUNDLE_LIST}" "${OUTPUT_PIPELINE_BUNDLE_LIST}"

# Build appstudio-utils image
if [ "$SKIP_BUILD" == "" ]; then
    echo "Using $QUAY_NAMESPACE to push results "
    docker build -t "$APPSTUDIO_UTILS_IMG" "$SCRIPTDIR/../appstudio-utils/"
    docker push "$APPSTUDIO_UTILS_IMG"

    # This isn't needed during PR testing
    if [[ "$BUILD_TAG" != "latest" && -z "$TEST_REPO_NAME" ]]; then
        # tag with latest
        IMAGE_NAME="${APPSTUDIO_UTILS_IMG%:*}:latest"
        docker tag "$APPSTUDIO_UTILS_IMG" "$IMAGE_NAME"
        docker push "$IMAGE_NAME"
    fi

fi

generated_pipelines_dir=$(mktemp -d -p "$WORKDIR" pipelines.XXXXXXXX)
oc kustomize --output "$generated_pipelines_dir" pipelines/

# Generate YAML files separately since pipelines for core services have same .metadata.name.
core_services_pipelines_dir=$(mktemp -d -p "$WORKDIR" core-services-pipelines.XXXXXXXX)
oc kustomize --output "$core_services_pipelines_dir" pipelines/core-services/

# Build tasks
(
cd "$SCRIPTDIR/.."
find task/*/*/ -maxdepth 0 -type d | awk -F '/' '{ print $0, $2, $3 }' | \
while read -r task_dir task_name task_version
do
    prepared_task_file="${WORKDIR}/$task_name-${task_version}.yaml"
    if [ -f "$task_dir/$task_name.yaml" ]; then
        cp "$task_dir/$task_name.yaml" "$prepared_task_file"
        task_file_sha=$(git log -n 1 --pretty=format:%H -- "$task_dir/$task_name.yaml")
    elif [ -f "$task_dir/kustomization.yaml" ]; then
        oc kustomize "$task_dir" > "$prepared_task_file"
        task_file_sha=$(sha256sum "$prepared_task_file" | awk '{print $1}')
    else
        echo Unknown task in "$task_dir"
        continue
    fi
    repository=${TEST_REPO_NAME:-task-${task_name}}
    tag=${TEST_REPO_NAME:+${task_name}-}${task_version}
    task_bundle=quay.io/$QUAY_NAMESPACE/${repository}:${tag}
    task_description=$(yq e '.spec.description' "$prepared_task_file" | head -n 1)

    if digest=$(skopeo inspect --no-tags --format='{{.Digest}}' docker://"${task_bundle}-${task_file_sha}" 2>/dev/null); then
      task_bundle_with_digest=${task_bundle}@${digest}
    else
      ANNOTATIONS=()
      ANNOTATIONS+=("org.opencontainers.image.source=${VCS_URL}")
      ANNOTATIONS+=("org.opencontainers.image.revision=${VCS_REF}")
      ANNOTATIONS+=("org.opencontainers.image.url=${VCS_URL}/tree/${VCS_REF}/${task_dir}")
      # yq will return null if the element is missing.
      if [[ "${task_description}" != "null" ]]; then
          ANNOTATIONS+=("org.opencontainers.image.description=${task_description}")
      fi
      if [ -f "${task_dir}/README.md" ]; then
          ANNOTATIONS+=("org.opencontainers.image.documentation=${VCS_URL}/tree/${VCS_REF}/${task_dir}README.md")
      fi
      if [ -f "${task_dir}/TROUBLESHOOTING.md" ]; then
          ANNOTATIONS+=("dev.tekton.docs.troubleshooting=${VCS_URL}/tree/${VCS_REF}/${task_dir}TROUBLESHOOTING.md")
      fi
      if [ -f "${task_dir}/USAGE.md" ]; then
          ANNOTATIONS+=("dev.tekton.docs.usage=${VCS_URL}/tree/${VCS_REF}/${task_dir}USAGE.md")
      fi

      ANNOTATION_FLAGS=()
      for annotation in "${ANNOTATIONS[@]}"; do
          ANNOTATION_FLAGS+=("--annotate" "$(escape_tkn_bundle_arg "$annotation")")
      done

      output=$(tkn_bundle_push "${ANNOTATION_FLAGS[@]}" -f "$prepared_task_file" "$task_bundle" | save_ref "$task_bundle" "$OUTPUT_TASK_BUNDLE_LIST")
      echo "$output"
      task_bundle_with_digest="${output##*$'\n'}"

      # copy task to new tag pointing to commit where the file was changed lastly, so that image persists
      # even when original tag is updated
      skopeo copy "docker://${task_bundle}" "docker://${task_bundle}-${task_file_sha}"
    fi
    # version placeholder is removed naturally by the substitution.
    real_task_name=$(yq e '.metadata.name' "$prepared_task_file")
    sub_expr_1="
        (.spec.tasks[].taskRef | select(.name == \"${real_task_name}\" and .version == \"${task_version}\" ))
        |= {\"resolver\": \"bundles\", \"params\": [ { \"name\": \"name\", \"value\": \"${real_task_name}\" } , { \"name\": \"bundle\", \"value\": \"${task_bundle_with_digest}\" }, { \"name\": \"kind\", \"value\": \"task\" }] }
    "
    sub_expr_2="
        (.spec.finally[].taskRef | select(.name == \"${real_task_name}\" and .version == \"${task_version}\" ))
        |= {\"resolver\": \"bundles\", \"params\": [ { \"name\": \"name\", \"value\": \"${real_task_name}\" } , { \"name\": \"bundle\", \"value\": \"${task_bundle_with_digest}\" },{ \"name\": \"kind\", \"value\": \"task\" }] }
    "
    for filename in "$generated_pipelines_dir"/*.yaml "$core_services_pipelines_dir"/*.yaml
    do
        yq e "$sub_expr_1" -i "${filename}"
        yq e "$sub_expr_2" -i "${filename}"
    done
done
)

# Used for build-definitions pull request CI only
if [ -n "$ENABLE_SOURCE_BUILD" ]; then
    for pipeline_yaml in "$generated_pipelines_dir"/*.yaml; do
        yq e '(.spec.params[] | select(.name == "build-source-image") | .default) = "true"' -i "$pipeline_yaml"
    done
fi

# Build Pipeline bundle with pipelines pointing to newly built task bundles
for pipeline_yaml in "$generated_pipelines_dir"/*.yaml "$core_services_pipelines_dir"/*.yaml
do
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

    tkn_bundle_push "${ANNOTATION_FLAGS[@]}" "$pipeline_bundle" -f "${pipeline_yaml}" | \
        save_ref "$pipeline_bundle" "$OUTPUT_PIPELINE_BUNDLE_LIST"

    [ "$pipeline_name" == "docker-build" ] && docker_pipeline_bundle=$pipeline_bundle
    [ "$pipeline_name" == "docker-build-oci-ta" ] && docker_oci_ta_pipeline_bundle=$pipeline_bundle
    [ "$pipeline_name" == "docker-build-multi-platform-oci-ta" ] && docker_multi_platform_oci_ta_pipeline_bundle=$pipeline_bundle
    [ "$pipeline_name" == "fbc-builder" ] && fbc_pipeline_bundle=$pipeline_bundle
    [ "$pipeline_name" == "nodejs-builder" ] && nodejs_pipeline_bundle=$pipeline_bundle
    [ "$pipeline_name" == "java-builder" ] && java_pipeline_bundle=$pipeline_bundle
    if [ "$SKIP_DEVEL_TAG" == "" ] && is_official_repo "$QUAY_NAMESPACE" && [ -z "$TEST_REPO_NAME" ]; then
        NEW_TAG="${pipeline_bundle%:*}:devel"
        skopeo copy "docker://${pipeline_bundle}" "docker://${NEW_TAG}"
    fi
done

if [ "$SKIP_INSTALL" == "" ]; then
    rm -f bundle_values.env

    echo "export CUSTOM_DOCKER_BUILD_PIPELINE_BUNDLE=$docker_pipeline_bundle" >> bundle_values.env
    echo "export CUSTOM_DOCKER_BUILD_OCI_TA_PIPELINE_BUNDLE=$docker_oci_ta_pipeline_bundle" >> bundle_values.env
    echo "export CUSTOM_DOCKER_BUILD_MULTI_PLATFORM_OCI_TA_PIPELINE_BUNDLE=$docker_multi_platform_oci_ta_pipeline_bundle" >> bundle_values.env
    echo "export CUSTOM_FBC_BUILDER_PIPELINE_BUNDLE=$fbc_pipeline_bundle" >> bundle_values.env
fi
