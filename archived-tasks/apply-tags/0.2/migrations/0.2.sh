#!/usr/bin/env bash

set -euo pipefail

# Created for task: apply-tags@0.2
# Creation time: 2025-06-05T10:43:11+00:00

declare -r pipeline_file=${1:?missing pipeline file}

# Determine the correct image-digest and image-url values based on task presence
if yq -e '.spec.tasks[] | select(.name == "build-oci-artifact")' "$pipeline_file" >/dev/null; then
    image_digest_value="\$(tasks.build-oci-artifact.results.IMAGE_DIGEST)"
    image_url_value="\$(tasks.build-oci-artifact.results.IMAGE_URL)"
elif yq -e '.spec.tasks[] | select(.name == "build-image-index")' "$pipeline_file" >/dev/null; then
    image_digest_value="\$(tasks.build-image-index.results.IMAGE_DIGEST)"
    image_url_value="\$(tasks.build-image-index.results.IMAGE_URL)"
elif yq -e '.spec.tasks[] | select(.name == "build-container")' "$pipeline_file" >/dev/null; then
    image_digest_value="\$(tasks.build-container.results.IMAGE_DIGEST)"
    image_url_value="\$(tasks.build-container.results.IMAGE_URL)"
else
    echo "Neither build-oci-artifact nor build-image-index tasks found."
    exit 0
fi

# Remove IMAGE parameter from apply-tags task if it exists. It is renamed to IMAGE_URL
if yq -e '.spec.tasks[] | select(.name == "apply-tags").params[] | select(.name == "IMAGE")' "$pipeline_file" >/dev/null; then
    echo "Removing IMAGE parameter from apply-tags task"
    yq -i '(.spec.tasks[] | select(.name == "apply-tags").params) |= map(select(.name != "IMAGE"))' "$pipeline_file"
else
    echo "IMAGE parameter not found in apply-tags task. Nothing to remove."
fi

# Check if IMAGE_URL parameter already exists using precise path
if ! yq -e '.spec.tasks[] | select(.name == "apply-tags").params[] | select(.name == "IMAGE_URL")' "$pipeline_file" >/dev/null; then
    echo "Adding image-url parameter to apply-tags task"
    yq -i "(.spec.tasks[] | select(.name == \"apply-tags\")).params += [{\"name\": \"IMAGE_URL\", \"value\": \"$image_url_value\"}]" "$pipeline_file"
else
    echo "IMAGE_URL parameter already exists in apply-tags task. No changes needed."
fi

# Check if IMAGE_DIGEST parameter already exists using precise path
if ! yq -e '.spec.tasks[] | select(.name == "apply-tags").params[] | select(.name == "IMAGE_DIGEST")' "$pipeline_file" >/dev/null; then
    echo "Adding image-digest parameter to apply-tags task"
    yq -i "(.spec.tasks[] | select(.name == \"apply-tags\")).params += [{\"name\": \"IMAGE_DIGEST\", \"value\": \"$image_digest_value\"}]" "$pipeline_file"
else
    echo "IMAGE_DIGEST parameter already exists in apply-tags task. No changes needed."
fi
