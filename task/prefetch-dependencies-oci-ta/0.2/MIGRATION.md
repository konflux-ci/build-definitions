# Migration from 0.1 to 0.2

Version 0.2:

* Changes the default SBOM format from CycloneDX to SPDX.

## Action from users

In order for a typical Konflux pipeline to work well with SPDX, all the tasks
that handle SBOMs must be SPDX-ready. Relevant tasks and required versions:

* Depending on the build task you use, one of:
  * `buildah >= 0.4`
  * `rpm-ostree >= ? (not SPDX-ready yet)`
  * `build-maven-zip >= ? (not SPDX-ready yet)`
* `source-build >= 0.2`
* `deprecated-image-check >= 0.5`

> Note: the same version constraints apply even if you use the `*-oci-ta` variants
> of these tasks or the `*-remote*` variants of the buildah task.

If your pipeline uses these tasks, please make sure their versions are high enough.
There's a good chance that the Pull Request which led you to this migration document
has updated every relevant task in your pipelines at once.
