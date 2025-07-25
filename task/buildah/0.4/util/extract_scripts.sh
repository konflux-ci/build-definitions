#!/bin/bash
set -euo pipefail

# Extract all scripts from buildah.yaml
YAML_FILE="buildah.yaml"
SCRIPTS_DIR="steps"

# Create scripts directory
mkdir -p "$SCRIPTS_DIR"

# Function to extract script using yq
extract_script() {
    local script_name=$1
    
    echo "Extracting $script_name..."
    
    # Use yq to extract the script content
    yq eval ".spec.steps[] | select(.name == \"$script_name\") | .script" "$YAML_FILE" > "$SCRIPTS_DIR/${script_name}.sh"
    
    # Make it executable
    chmod +x "$SCRIPTS_DIR/${script_name}.sh"
}

# Extract each script by name
extract_script "build"
extract_script "push" 
extract_script "sbom-syft-generate"
extract_script "prepare-sboms"
extract_script "upload-sbom"
extract_script "reuse-sbom"
extract_script "remove-expires-label"

echo "Scripts extracted to $SCRIPTS_DIR/"
ls -la "$SCRIPTS_DIR/" 