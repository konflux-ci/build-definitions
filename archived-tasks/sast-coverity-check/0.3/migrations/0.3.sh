#!/usr/bin/env bash

set -euo pipefail

# Created for task: sast-coverity-check@0.3
# Creation time: 2025-03-28T10:28:54Z

declare -r pipeline_file=${1:?missing pipeline file}

# Determine the correct image-digest and image-url values based on task presence
if yq -e '.spec.tasks[] | select(.name == "build-oci-artifact")' "$pipeline_file" >/dev/null; then
    image_digest_value="\$(tasks.build-oci-artifact.results.IMAGE_DIGEST)"
    image_url_value="\$(tasks.build-oci-artifact.results.IMAGE_URL)"
elif yq -e '.spec.tasks[] | select(.name == "build-image-index")' "$pipeline_file" >/dev/null; then
    image_digest_value="\$(tasks.build-image-index.results.IMAGE_DIGEST)"
    image_url_value="\$(tasks.build-image-index.results.IMAGE_URL)"
else
    echo "Neither build-oci-artifact nor build-image-index tasks found."
    exit 0
fi

# Check if image-digest parameter already exists using precise path
if ! yq -e '.spec.tasks[] | select(.name == "sast-coverity-check").params[] | select(.name == "image-digest")' "$pipeline_file" >/dev/null; then
    echo "Adding image-digest parameter to sast-coverity-check task"
    yq -i "(.spec.tasks[] | select(.name == \"sast-coverity-check\")).params += [{\"name\": \"image-digest\", \"value\": \"$image_digest_value\"}]" "$pipeline_file"
else
    echo "image-digest parameter already exists in sast-coverity-check task. No changes needed."
fi

# Check if image-url parameter already exists using precise path
if ! yq -e '.spec.tasks[] | select(.name == "sast-coverity-check").params[] | select(.name == "image-url")' "$pipeline_file" >/dev/null; then
    echo "Adding image-url parameter to sast-coverity-check task"
    yq -i "(.spec.tasks[] | select(.name == \"sast-coverity-check\")).params += [{\"name\": \"image-url\", \"value\": \"$image_url_value\"}]" "$pipeline_file"
else
    echo "image-url parameter already exists in sast-coverity-check task. No changes needed."
fi