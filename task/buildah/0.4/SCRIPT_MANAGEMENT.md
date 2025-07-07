# Script Management System for Buildah Task

This document explains how to use the new script management system in the `task/buildah/0.4` directory. The system allows you to maintain shell scripts separately from the YAML file, enabling better linting, version control, and development workflow.

## tl;dr:
to edit the buildah (including all variants, like oci-ta or remote) task you should ONLY every 
update the files in this dir, and then run 'make taskyaml'

## Overview

The script management system consists of:

- **Template file**: `buildah.template.yaml` - Contains the Tekton task definition with script placeholders
- **Script files**: `steps/*.sh` - Individual shell scripts for each step
- **Embedding script**: `util/embed_scripts_simple2.sh` - Embeds scripts into the final YAML
- **Extraction script**: `util/extract_scripts.sh` - Extracts scripts from YAML for editing
- **Makefile**: `Makefile` - Orchestrates the build and validation process

## How to Edit the Buildah Task

**This is the most important section!** Here's how to modify the buildah task:

### 1. Edit the Scripts

To modify task behavior, edit the scripts in the `steps/` directory:

```bash
# Edit the build script (main build logic)
vim steps/build.sh

# Edit the push script (image pushing logic)
vim steps/push.sh

# Edit SBOM generation
vim steps/sbom-syft-generate.sh

# Edit SBOM preparation
vim steps/prepare-sboms.sh

# Edit SBOM upload
vim steps/upload-sbom.sh

# Edit SBOM reuse logic
vim steps/reuse-sbom.sh

# Edit label removal
vim steps/remove-expires-label.sh
```

### 2. Validate Your Changes

After editing scripts, validate them:

```bash
make shellcheck
```

This will check all scripts for syntax errors and style issues.

### 3. Generate the Updated YAML

Embed your changes into the final YAML:

```bash
make taskyaml
```

This will:
- Run shellcheck on all scripts
- Embed scripts into the YAML template
- Validate the final YAML with yamllint

### 4. Generate Related Tasks (Optional)

If you need to update the related task variants:

```bash
make generate-all
```

This generates the trusted artifacts and remote versions of the task.

### 5. Test Your Changes

Always test your changes before committing:

```bash
# Validate the generated YAML
yamllint buildah.yaml

# Check that all scripts are valid
make shellcheck

# Ensure the full workflow works
make taskyaml
```

## Directory Structure

```
task/buildah/0.4/
├── buildah.template.yaml         # Template with script placeholders
├── buildah.yaml                 # Generated final YAML (do not edit directly)
├── steps/                       # Individual script files
│   ├── build.sh
│   ├── push.sh
│   ├── sbom-syft-generate.sh
│   ├── prepare-sboms.sh
│   ├── upload-sbom.sh
│   ├── reuse-sbom.sh
│   └── remove-expires-label.sh
├── util/                        # Utility scripts
│   └── extract_scripts.sh       # Extracts scripts from YAML
├── util/                        # Utility scripts
│   ├── embed_scripts_simple2.sh # Embeds scripts into YAML
│   └── extract_scripts.sh       # Extracts scripts from YAML
├── Makefile                     # Build and validation targets
└── SCRIPT_MANAGEMENT.md         # This document
```

## Workflow

### 1. Editing Scripts

To edit a script, modify the corresponding file in the `steps/` directory:

```bash
# Edit the build script
vim steps/build.sh

# Edit the push script
vim steps/push.sh

# etc.
```

### 2. Validating Scripts

Run shellcheck on all scripts:

```bash
make shellcheck
```

This will validate all scripts in the `steps/` directory for syntax errors, style issues, and potential problems.

### 3. Generating the Final YAML

To embed the scripts into the YAML template:

```bash
make taskyaml
```

This target:
1. Runs `shellcheck` on all scripts
2. Embeds scripts into `buildah.template.yaml` to create `buildah.yaml`
3. Validates the final YAML with `yamllint`

### 4. Generating Related Tasks

To generate the related trusted artifacts and remote tasks:

```bash
make generate-all
```

This generates:
- `buildah-oci-ta.yaml` - Trusted artifacts version
- `buildah-remote.yaml` - Remote version
- `buildah-oci-ta-remote.yaml` - Remote trusted artifacts version

## Available Make Targets

### `make shellcheck`
Runs shellcheck on all scripts in the `steps/` directory.

### `make taskyaml`
Main target that:
- Runs shellcheck
- Embeds scripts into YAML
- Validates with yamllint

### `make embed-scripts`
Manually runs the embedding script.

### `make generate-ta-tasks`
Generates the trusted artifacts version of the task.

### `make generate-buildah-remote`
Generates the remote version of the task.

### `make generate-all`
Generates all related task variants.

### `make clean`
Removes generated files and the `steps/` directory.

### `make help`
Shows available make targets.

## Script Placeholders

The template file `buildah.template.yaml` contains placeholders for each script:

```yaml
steps:
  - name: build
    # ... other properties
    script: __SCRIPT_CONTENT_build__

  - name: push
    # ... other properties
    script: __SCRIPT_CONTENT_push__

  # ... etc for all steps
```

The embedding script replaces these placeholders with the actual script content from the `steps/` directory.

## Manual Script Extraction

If you need to extract scripts from an existing YAML file:

```bash
./util/extract_scripts.sh
```

This will:
1. Parse the `buildah.yaml` file
2. Extract each script section
3. Save individual scripts to the `steps/` directory

## Development Tips

### 1. Always Edit Scripts in `steps/`
Never edit the scripts directly in `buildah.yaml`. Always modify the files in the `steps/` directory.

### 2. Run Validation Before Committing
Always run `make taskyaml` before committing changes to ensure:
- All scripts pass shellcheck
- The final YAML is valid
- No syntax errors are introduced

### 3. Use the Makefile
The Makefile provides convenient shortcuts for common operations. Use it instead of running individual commands.

### 4. Check Generated Files
After running `make generate-all`, check that the generated files are correct and up to date.

## Troubleshooting

### YAML Validation Errors
If `yamllint` fails:
1. Check that the template file `buildah.template.yaml` has correct indentation
2. Ensure the embedding script is working correctly
3. Verify that all scripts have proper syntax

### Shellcheck Errors
If `shellcheck` fails:
1. Fix the issues in the individual script files
2. Common issues include unused variables, missing quotes, etc.
3. Run `make shellcheck` again to verify fixes

### Script Not Found
If the embedding script can't find a script:
1. Check that the script file exists in the `steps/` directory
2. Verify the filename matches the placeholder name
3. Ensure the script file has the correct permissions

### Generation Errors
If the generate scripts fail:
1. Ensure `buildah.yaml` is valid and passes yamllint
2. Check that all required parameters are present
3. Verify the task structure is correct

## File Descriptions

### `buildah.template.yaml`
Template file containing the Tekton task definition with script placeholders. This is the source of truth for the task structure.

### `buildah.yaml`
Generated final YAML file. This is what gets deployed and used by Tekton. **Do not edit this file directly.**

### `steps/*.sh`
Individual shell scripts for each step. These are the files you should edit when modifying task behavior.

### `util/embed_scripts_simple2.sh`
Script that embeds the individual script files into the YAML template. It:
- Reads the template file line by line
- Finds script placeholders
- Replaces them with the actual script content
- Preserves proper YAML indentation

### `util/extract_scripts.sh`
Script that extracts embedded scripts from a YAML file. Useful for migrating from the old system or debugging.

### `Makefile`
Orchestrates the build process and provides convenient targets for common operations.

## Cleanup

To clean up all generated files and temporary files:

```bash
make clean
```

This will remove:
- Generated YAML files
- Temporary files (`*.tmp`, `*.backup`, `*.bak`, `*~`, `*.yaml-e`)
- Extracted scripts directory
- Virtual environment directory

**Note**: `*.yaml-e` files are created by `sed` when using the `-i` flag without specifying a backup extension.

**Note**: This system uses `yq` for YAML operations instead of `sed` to ensure proper YAML parsing and avoid fragile text-based manipulations.

## Migration from Old System

If you're migrating from the old system where scripts were embedded directly in the YAML:

1. Run `./util/extract_scripts.sh` to extract existing scripts
2. Edit the scripts in the `steps/` directory
3. Use `make taskyaml` to regenerate the YAML
4. Test that everything works correctly

## Best Practices

1. **Keep scripts focused**: Each script should have a single responsibility
2. **Use proper error handling**: Scripts should fail fast and provide clear error messages
3. **Follow shellcheck guidelines**: Address all shellcheck warnings and errors
4. **Test thoroughly**: Always test the generated YAML before committing
5. **Document changes**: Update this document when adding new scripts or changing the workflow 