#!/usr/bin/env bash
set -o errexit
set -o nounset
set -o pipefail

# Bundle Sanity Validation Script
# This script validates the data-acceptable-bundles content before updating the :latest tag
# to prevent broken data from being pushed to production.

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Global variables
BUNDLE_REPO="${BUNDLE_REPO:-${DATA_BUNDLE_REPO:-quay.io/konflux-ci/tekton-catalog/data-acceptable-bundles}}"
NEW_TAG="${NEW_TAG:-${DATA_BUNDLE_TAG}}"
LATEST_TAG="latest"

# Override flag for CI scenarios
FORCE_UPDATE_LATEST="${FORCE_UPDATE_LATEST:-false}"

# Logging functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $*"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $*"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*"
}

# Function to extract bundle content from OCI image
extract_bundle_content() {
    local image_ref="$1"
    local output_file="$2"

    log_info "Extracting bundle content from ${image_ref}..."

    # Create a temporary directory for extraction
    local temp_dir
    temp_dir=$(mktemp -d)
    trap 'rm -rf '"${temp_dir}" EXIT

    # Use skopeo to copy the image to a local directory
    if ! skopeo copy "docker://${image_ref}" "dir:${temp_dir}" 2>&1; then
        log_error "Failed to extract bundle from ${image_ref}"
        log_error "Check if the image exists and you have access to it"
        return 1
    fi

    # Find and extract the bundle YAML file
    # Look for .yaml/.yml files first, then look for any file that might contain YAML content
    local bundle_file
    bundle_file=$(find "${temp_dir}" -name "*.yaml" -o -name "*.yml" | head -1)

    # If no .yaml/.yml files found, look for any file that might contain YAML content
    if [[ -z "${bundle_file}" ]]; then
        # Look for files that contain YAML-like content (starting with --- or trusted_tasks)
        while IFS= read -r file; do
            if head -1 "${file}" | grep -q "^---\|^trusted_tasks:"; then
                bundle_file="${file}"
                break
            fi
        done < <(find "${temp_dir}" -type f ! -name "manifest.json" ! -name "version")
    fi

    if [[ -z "${bundle_file}" ]]; then
        log_error "No YAML file found in bundle ${image_ref}"
        return 1
    fi

    cp "${bundle_file}" "${output_file}"
    log_info "Bundle content extracted to ${output_file}"
}

# Function to validate YAML schema
validate_schema() {
    local bundle_file="$1"

    log_info "Validating bundle schema..."

    # Check if file exists and is readable
    if [[ ! -f "${bundle_file}" ]]; then
        log_error "Bundle file ${bundle_file} does not exist"
        return 1
    fi

    # Check if file is valid YAML
    if ! yq eval '.' "${bundle_file}" >/dev/null 2>&1; then
        log_error "Bundle file ${bundle_file} is not valid YAML"
        return 1
    fi

    # Check if trusted_tasks key exists
    if ! yq eval -e '.trusted_tasks' "${bundle_file}" >/dev/null 2>&1; then
        log_error "Bundle file ${bundle_file} is missing 'trusted_tasks' key"
        return 1
    fi

    # Validate structure of trusted_tasks entries
    local task_count=0
    local invalid_entries=0

    while IFS= read -r task_path; do
        task_count=$((task_count + 1))

        # Get the entries for this task
        local entries
        entries=$(yq eval ".trusted_tasks[\"${task_path}\"]" "${bundle_file}")

        # Check if entries is an array
        if ! echo "${entries}" | yq eval -e 'type == "!!seq"' >/dev/null 2>&1; then
            log_error "Task ${task_path} entries are not an array"
            invalid_entries=$((invalid_entries + 1))
            continue
        fi

        # Validate each entry in the array
        local entry_count
        entry_count=$(echo "${entries}" | yq eval 'length')
        for ((i=0; i<entry_count; i++)); do
            local entry
            entry=$(echo "${entries}" | yq eval ".[${i}]")

            # Check if entry is an object (not a string)
            if ! echo "${entry}" | yq eval -e 'type == "!!map"' >/dev/null 2>&1; then
                log_error "Task ${task_path} entry ${i} is not an object (found: $(echo "${entry}" | yq eval 'type'))"
                invalid_entries=$((invalid_entries + 1))
                continue
            fi

            # Check if entry has 'ref' field
            if ! echo "${entry}" | yq eval -e 'has("ref")' >/dev/null 2>&1; then
                log_error "Task ${task_path} entry ${i} is missing 'ref' field"
                invalid_entries=$((invalid_entries + 1))
                continue
            fi

            # Check if ref is not empty
            local ref_value
            ref_value=$(echo "${entry}" | yq eval '.ref')
            if [[ -z "${ref_value}" || "${ref_value}" == "null" ]]; then
                log_error "Task ${task_path} entry ${i} has empty or null 'ref' field"
                invalid_entries=$((invalid_entries + 1))
                continue
            fi

            # Check for old effective_on field (should be expires_on) - check ALL entries
            if echo "${entry}" | yq eval 'has("effective_on")' | grep -q "true"; then
                log_error "Task ${task_path} entry ${i} has deprecated 'effective_on' field (should be 'expires_on')"
                invalid_entries=$((invalid_entries + 1))
                continue
            fi

            # For entries after the first one, check if they have expires_on field
            if [[ ${i} -gt 0 ]]; then
                if ! echo "${entry}" | yq eval -e 'has("expires_on")' >/dev/null 2>&1; then
                    log_error "Task ${task_path} entry ${i} is missing 'expires_on' field (required for non-latest entries)"
                    invalid_entries=$((invalid_entries + 1))
                    continue
                fi

                # Validate expires_on format (ISO 8601)
                local expires_on
                expires_on=$(echo "${entry}" | yq eval '.expires_on')
                if [[ -z "${expires_on}" || "${expires_on}" == "null" ]]; then
                    log_error "Task ${task_path} entry ${i} has empty or null 'expires_on' field"
                    invalid_entries=$((invalid_entries + 1))
                    continue
                fi

                # Basic ISO 8601 format check (YYYY-MM-DDTHH:MM:SSZ)
                if ! [[ "${expires_on}" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$ ]]; then
                    log_error "Task ${task_path} entry ${i} has invalid 'expires_on' format: ${expires_on} (expected ISO 8601)"
                    invalid_entries=$((invalid_entries + 1))
                    continue
                fi
            fi

            # Check for suspicious date values that indicate data generation errors
            local suspicious_dates=0
            for field in $(echo "${entry}" | yq eval 'keys[]' 2>/dev/null); do
                local field_value
                field_value=$(echo "${entry}" | yq eval ".[\"${field}\"]")

                # Check if field value looks like a date
                if [[ "${field_value}" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$ ]]; then
                    # Check for suspicious date patterns
                    case "${field_value}" in
                        "0001-01-01T00:00:00Z")
                            log_error "Task ${task_path} entry ${i} has suspicious zero date value in field '${field}': ${field_value} (indicates data generation error)"
                            suspicious_dates=$((suspicious_dates + 1))
                            ;;
                        "1970-01-01T00:00:00Z")
                            log_error "Task ${task_path} entry ${i} has suspicious Unix epoch date in field '${field}': ${field_value} (indicates data generation error)"
                            suspicious_dates=$((suspicious_dates + 1))
                            ;;
                        "1900-01-01T00:00:00Z")
                            log_error "Task ${task_path} entry ${i} has suspicious 1900 date in field '${field}': ${field_value} (indicates data generation error)"
                            suspicious_dates=$((suspicious_dates + 1))
                            ;;
                    esac

                    # Check for future dates that are too far in the future (more than 10 years)
                    local year
                    year=$(echo "${field_value}" | cut -d'-' -f1)
                    local current_year
                    current_year=$(date +%Y)
                    if [[ ${year} -gt $((current_year + 10)) ]]; then
                        log_error "Task ${task_path} entry ${i} has suspicious future date in field '${field}': ${field_value} (year ${year} is more than 10 years in the future)"
                        suspicious_dates=$((suspicious_dates + 1))
                    fi

                    # Check for dates that are too far in the past (before 2020)
                    if [[ ${year} -lt 2020 ]]; then
                        log_error "Task ${task_path} entry ${i} has suspicious old date in field '${field}': ${field_value} (year ${year} is before 2020, likely indicates data generation error)"
                        suspicious_dates=$((suspicious_dates + 1))
                    fi
                fi
            done

            if [[ ${suspicious_dates} -gt 0 ]]; then
                invalid_entries=$((invalid_entries + suspicious_dates))
                continue
            fi
        done
    done < <(yq eval '.trusted_tasks | keys | .[]' "${bundle_file}")

    if [[ ${invalid_entries} -gt 0 ]]; then
        log_error "Schema validation failed: ${invalid_entries} invalid entries found out of ${task_count} tasks"
        log_error "Bundle: ${BUNDLE_REPO}:${NEW_TAG}"
        return 1
    fi

    log_info "Schema validation passed: ${task_count} tasks validated successfully"
    return 0
}

# Function to validate data integrity by comparing with current :latest
validate_data_integrity() {
    local new_bundle_file="$1"
    local latest_bundle_file="$2"

    log_info "Validating data integrity by comparing with current :latest..."

    # Check if latest bundle exists
    if [[ ! -f "${latest_bundle_file}" ]]; then
        log_warn "No current :latest bundle found for comparison, skipping integrity checks"
        return 0
    fi

    # Count tasks in both bundles
    local new_task_count
    new_task_count=$(yq eval '.trusted_tasks | keys | length' "${new_bundle_file}")
    local latest_task_count
    latest_task_count=$(yq eval '.trusted_tasks | keys | length' "${latest_bundle_file}")

    log_info "New bundle has ${new_task_count} tasks, latest bundle has ${latest_task_count} tasks"

    # Check for significant data loss (more than 50% reduction)
    if [[ ${latest_task_count} -gt 0 ]]; then
        local reduction_percent=$(( (latest_task_count - new_task_count) * 100 / latest_task_count ))
        if [[ ${reduction_percent} -gt 50 ]]; then
            log_error "Significant data loss detected: ${reduction_percent}% reduction in task count (${latest_task_count} → ${new_task_count})"
            log_error "Bundle: ${BUNDLE_REPO}:${NEW_TAG}"
            return 1
        fi
    fi

    # Check for significant reduction in entries per task
    local tasks_with_reduction=0
    while IFS= read -r task_path; do
        local new_entry_count
        new_entry_count=$(yq eval ".trusted_tasks[\"${task_path}\"] | length" "${new_bundle_file}" 2>/dev/null || echo "0")
        local latest_entry_count
        latest_entry_count=$(yq eval ".trusted_tasks[\"${task_path}\"] | length" "${latest_bundle_file}" 2>/dev/null || echo "0")

        if [[ ${latest_entry_count} -gt 0 && ${new_entry_count} -lt $((latest_entry_count / 2)) ]]; then
            log_warn "Task ${task_path} has significant entry reduction: ${latest_entry_count} → ${new_entry_count}"
            tasks_with_reduction=$((tasks_with_reduction + 1))
        fi
    done < <(yq eval '.trusted_tasks | keys | .[]' "${new_bundle_file}")

    # Fail if too many tasks have significant reductions
    if [[ ${tasks_with_reduction} -gt 5 ]]; then
        log_error "Too many tasks have significant entry reductions: ${tasks_with_reduction} tasks affected"
        log_error "Bundle: ${BUNDLE_REPO}:${NEW_TAG}"
        return 1
    fi

    log_info "Data integrity validation passed"
    return 0
}

# Function to validate bundle content
validate_bundle() {
    local new_image_ref="${BUNDLE_REPO}:${NEW_TAG}"
    local latest_image_ref="${BUNDLE_REPO}:${LATEST_TAG}"

    log_info "Starting bundle validation for ${new_image_ref}"

    # Create temporary files for bundle content
    local new_bundle_file
    new_bundle_file=$(mktemp)
    local latest_bundle_file
    latest_bundle_file=$(mktemp)

    # Cleanup function
    cleanup() {  # shellcheck disable=SC2317
        rm -f "${new_bundle_file}" "${latest_bundle_file}"
    }
    trap cleanup EXIT

    # Extract bundle content
    if ! extract_bundle_content "${new_image_ref}" "${new_bundle_file}"; then
        log_error "Failed to extract new bundle content"
        return 1
    fi

    # Try to extract latest bundle content (may fail if it doesn't exist)
    if ! extract_bundle_content "${latest_image_ref}" "${latest_bundle_file}" 2>/dev/null; then
        log_warn "Could not extract latest bundle content for comparison"
        latest_bundle_file=""
    fi

    # Run validations
    if ! validate_schema "${new_bundle_file}"; then
        log_error "Schema validation failed"
        if [[ "${FORCE_UPDATE_LATEST}" != "true" ]]; then
            return 1
        else
            log_warn "⚠️  FORCE_UPDATE_LATEST=true - Continuing despite schema validation failure"
        fi
    fi
    
    if [[ -n "${latest_bundle_file}" ]]; then
        if ! validate_data_integrity "${new_bundle_file}" "${latest_bundle_file}"; then
            log_error "Data integrity validation failed"
            if [[ "${FORCE_UPDATE_LATEST}" != "true" ]]; then
                return 1
            else
                log_warn "⚠️  FORCE_UPDATE_LATEST=true - Continuing despite data integrity validation failure"
            fi
        fi
    fi

    # Log override status
    if [[ "${FORCE_UPDATE_LATEST}" == "true" ]]; then
        echo ""
        log_warn "=== OVERRIDE FLAG ACTIVE ==="
        log_warn "FORCE_UPDATE_LATEST=true"
        echo ""
    fi

    log_info "All bundle validations passed successfully"
    return 0
}

# Main execution
main() {
    log_info "Starting bundle sanity validation..."

    if [[ -z "${NEW_TAG}" ]]; then
        log_error "DATA_BUNDLE_TAG environment variable is required"
        exit 1
    fi

    if ! validate_bundle; then
        log_error "Bundle validation failed - NOT updating :latest tag"
        log_error "Failed bundle: ${BUNDLE_REPO}:${NEW_TAG}"
        exit 1
    fi

    log_info "Bundle validation successful - safe to update :latest tag"
    log_info "Validated bundle: ${BUNDLE_REPO}:${NEW_TAG}"
    exit 0
}

# Run main function
main "$@"
