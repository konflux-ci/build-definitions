#!/usr/bin/env bash

set -euo pipefail

# Based on task/sast-coverity-check/0.3/migrations/0.3.sh

declare -r pipeline_file=${1:?missing pipeline file}

tasks_root=".spec.tasks[]"
if yq -e ".spec.pipelineSpec.tasks" "$pipeline_file" &>/dev/null; then
  tasks_root=".spec.pipelineSpec.tasks[]"
fi

# Determine the correct image-digest and image-url values based on task presence
if yq -e "$tasks_root"' | select(.name == "build-oci-artifact")' "$pipeline_file" >/dev/null; then
    image_digest_value="\$(tasks.build-oci-artifact.results.IMAGE_DIGEST)"
    image_url_value="\$(tasks.build-oci-artifact.results.IMAGE_URL)"
elif yq -e "$tasks_root"' | select(.name == "build-image-index")' "$pipeline_file" >/dev/null; then
    image_digest_value="\$(tasks.build-image-index.results.IMAGE_DIGEST)"
    image_url_value="\$(tasks.build-image-index.results.IMAGE_URL)"
else
    echo "Neither build-oci-artifact nor build-image-index tasks found."
    exit 0
fi

# Check if image-digest parameter already exists using precise path
if yq -e "$tasks_root"' | select(.name == "sast-unicode-check")' "$pipeline_file" >/dev/null && ! yq -e "$tasks_root"' | select(.name == "sast-unicode-check").params[] | select(.name == "image-digest")' "$pipeline_file" >/dev/null; then
    echo "Adding image-digest parameter to sast-unicode-check task"
    yq -i "($tasks_root | select(.name == \"sast-unicode-check\")).params += [{\"name\": \"image-digest\", \"value\": \"$image_digest_value\"}]" "$pipeline_file"
elif yq -e "$tasks_root"' | select(.name == "sast-unicode-check-oci-ta")' "$pipeline_file" >/dev/null && ! yq -e "$tasks_root"' | select(.name == "sast-unicode-check-oci-ta").params[] | select(.name == "image-digest")' "$pipeline_file" >/dev/null; then
    echo "Adding image-digest parameter to sast-unicode-check-oci-ta task"
    yq -i "($tasks_root | select(.name == \"sast-unicode-check-oci-ta\")).params += [{\"name\": \"image-digest\", \"value\": \"$image_digest_value\"}]" "$pipeline_file"
else
    echo "image-digest parameter already exists in sast-unicode-check(-oci-ta) task or task doesn't exist. No changes needed."
fi

# Check if image-url parameter already exists using precise path
if yq -e "$tasks_root"' | select(.name == "sast-unicode-check")' "$pipeline_file" >/dev/null && ! yq -e "$tasks_root"' | select(.name == "sast-unicode-check").params[] | select(.name == "image-url")' "$pipeline_file" >/dev/null; then
    echo "Adding image-url parameter to sast-unicode-check task"
    yq -i "($tasks_root | select(.name == \"sast-unicode-check\")).params += [{\"name\": \"image-url\", \"value\": \"$image_url_value\"}]" "$pipeline_file"
elif yq -e "$tasks_root"' | select(.name == "sast-unicode-check-oci-ta")' "$pipeline_file" >/dev/null && ! yq -e "$tasks_root"' | select(.name == "sast-unicode-check-oci-ta").params[] | select(.name == "image-url")' "$pipeline_file" >/dev/null; then
    echo "Adding image-url parameter to sast-unicode-check-oci-ta task"
    yq -i "($tasks_root | select(.name == \"sast-unicode-check-oci-ta\")).params += [{\"name\": \"image-url\", \"value\": \"$image_url_value\"}]" "$pipeline_file"
else
    echo "image-url parameter already exists in sast-unicode-check(-oci-ta) task or task doesn't exist. No changes needed."
fi
