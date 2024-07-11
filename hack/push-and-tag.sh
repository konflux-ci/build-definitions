#!/bin/bash

SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
# File containing the list of images
OUTPUT_TASK_BUNDLE_LIST="${OUTPUT_TASK_BUNDLE_LIST-${SCRIPTDIR}/../task-bundle-list}"

# Read the file and process each line
while IFS=, read -r original_image new_image; do
    # Remove the quotes from the strings
    original_image=$(echo "$original_image" | tr -d '"' | xargs)
    new_image=$(echo "$new_image" | tr -d '"' | xargs)

    # Run the skopeo copy command
    echo "Copying from $original_image to $new_image"
    skopeo copy "docker://$original_image" "docker://$new_image"
  
done < "$OUTPUT_TASK_BUNDLE_LIST"
