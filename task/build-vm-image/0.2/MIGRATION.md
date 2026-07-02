# Migration from 0.1 to 0.2

Version 0.2 adds SBOM propagation and attachment to disk image artifacts.

## What changed

The task now downloads the SBOM from the source bootc container image and
attaches it to the built disk image OCI artifact using cosign. Two new
steps were added: `sbom-download` and `upload-sbom`.

New optional parameters:

* `SBOM_TYPE` (default: `spdx`) — the SBOM format for attachment. Valid
  values: `spdx`, `cyclonedx`.
* `SKIP_SBOM_GENERATION` (default: `false`) — skip SBOM propagation
  entirely. The parameter name follows the convention used by the
  `buildah` build task; for `build-vm-image`
  this controls SBOM *propagation* from the source container rather than
  generation, since the disk image SBOM is downloaded (not generated).

New result:

* `SBOM_BLOB_URL` — digest reference of the attached SBOM blob

### Hardening improvements over 0.1

* `validate-bib-config` now uses `set -euo pipefail` (was `set -e`).
* Pullspec values written to the shared vars file are escaped with
  `printf %q` to prevent shell metacharacter injection when sourced.
* Pullspec validation character class now includes `._-` and the regex
  logic is no longer inverted (0.1 had a bug where the `!` negation
  made the check a no-op).

## Action from users

No action required. The new parameters have defaults and the new result is
not referenced by existing pipelines. SBOM propagation is enabled by default.

To disable SBOM propagation, set `SKIP_SBOM_GENERATION` to `true`.
