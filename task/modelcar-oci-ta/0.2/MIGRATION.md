# Migration from 0.1 to 0.2

Version 0.2:

* Scans the ModelCar base image with Syft during `sbom-generate` and merges
  those packages into the composition SBOM (SPDX only; the default).
* CycloneDX builds keep the composition-only SBOM (no Syft merge).

## Action from users

* Pin pipelines to the `modelcar-oci-ta:0.2` task bundle after it is published.
* Expect additional `pkg:rpm/...` (and similar) packages in the attached SPDX
  SBOM; composition nodes (modelcar / base / model) are unchanged.
* No pipeline parameter changes are required.
