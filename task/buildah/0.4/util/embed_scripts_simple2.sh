#!/bin/bash
set -euo pipefail

TEMPLATE_FILE="buildah.template.yaml"
OUTPUT_FILE="buildah.yaml"
SCRIPTS_DIR="steps"

echo "Embedding scripts into YAML..."

# Start with empty output file
> "$OUTPUT_FILE"

# List of scripts to embed
scripts=(
    "pre-build"
    "build"
    "push"
    "sbom-syft-generate"
    "prepare-sboms"
    "upload-sbom"
)

# Process the template line by line
while IFS= read -r line; do
    # Check if this line contains a script placeholder
    script_found=false
    for script_name in "${scripts[@]}"; do
        placeholder="__SCRIPT_CONTENT_${script_name}__"
        if [[ "$line" == *"$placeholder"* ]]; then
            script_file="$SCRIPTS_DIR/${script_name}.sh"
            if [ -f "$script_file" ]; then
                echo "Embedding $script_name.sh..."
                # Output the script: | line
                echo "      script: |" >> "$OUTPUT_FILE"
                # Output the script content with proper indentation
                while IFS= read -r script_line; do
                    # Remove trailing spaces and indent with 8 spaces
                    script_line="${script_line%"${script_line##*[! ]}"}"
                    # Only output non-empty lines (trim blank lines during embedding)
                    if [ -n "$script_line" ]; then
                        echo "        $script_line" >> "$OUTPUT_FILE"
                    fi
                done < "$script_file"
                # Don't add any blank line - the script content already ends with a newline
            else
                echo "Warning: Script file $script_file not found"
                echo "$line" >> "$OUTPUT_FILE"
            fi
            script_found=true
            break
        fi
    done
    
    # If no script placeholder found, output the line as-is
    if [ "$script_found" = false ]; then
        echo "$line" >> "$OUTPUT_FILE"
    fi
done < "$TEMPLATE_FILE"

echo "All scripts embedded successfully!" 