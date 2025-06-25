#!/usr/bin/env bash

set -euo pipefail

declare -r pipeline_file=${1:?missing pipeline file}

tasks_root=".spec.tasks[]"
if yq -e ".spec.pipelineSpec.tasks" "$pipeline_file" &>/dev/null; then
  tasks_root=".spec.pipelineSpec.tasks[]"
fi

# check if image-url and image-digest is missing for sast-unicode-check task and early exit
if yq -e "$tasks_root"' | select(.name == "sast-unicode-check").params[] | has(.name == "image-url") && has(.name == "image-digest"' "$pipeline_file" &>/dev/null; then
  echo "image-url and image-digest already set for sast-unicode-check"
  exit 0
fi

# get image-url and image-digest value from other tasks
if yq -e "$tasks_root"' | select(.name == "build-oci-artifact")' "$pipeline_file" &>/dev/null; then
    image_url_value="\$(tasks.build-oci-artifact.results.IMAGE_URL)"
    image_digest_value="\$(tasks.build-oci-artifact.results.IMAGE_DIGEST)"
elif yq -e "$tasks_root"' | select(.name == "build-image-index")' "$pipeline_file" &>/dev/null; then
    image_url_value="\$(tasks.build-oci-artifact.results.IMAGE_URL)"
    image_digest_value="\$(tasks.build-image-index.results.IMAGE_DIGEST)"
else
    echo "Neither build-oci-artifact nor build-image-index tasks found. Can't get image-url and image-digest."
    exit 0
fi

# add params to sast-unicode-check
if ! yq -e "$tasks_root"' | select(.name == "sast-unicode-check").params[] | select(.name == "image-url")' "$pipeline_file" &>/dev/null; then
  yq -e -i "($tasks_root | select(.name == \"sast-unicode-check\")).params += [{\"name\": \"image-url\", \"value\": \"$image_url_value\"}]" "$pipeline_file"
  echo "image-url added to sast-unicode-check"
fi
if ! yq -e "$tasks_root"' | select(.name == "sast-unicode-check").params[] | select(.name == "image-digest")' "$pipeline_file" &>/dev/null; then
  yq -e -i "($tasks_root | select(.name == \"sast-unicode-check\")).params += [{\"name\": \"image-digest\", \"value\": \"$image_digest_value\"}]" "$pipeline_file"
  echo "image-digest added to sast-unicode-check"
fi
