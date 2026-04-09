# Migration from 0.1 to 0.2

## Parameter Changes

### Added Parameters
- `IMAGE`: Full image reference with tag (replaces `REPO`)
- `IMAGE_MAPPINGS`: JSON array for image substitution in Helm charts
- `VALUES_FILE`: Path to values file for image substitution (default: `values.yaml`)

### Modified Parameters
- `REPO` → `IMAGE`: Now requires full image reference including tag

### Removed Parameters
- None

## Action from users

The task is assumed to have no active users.
