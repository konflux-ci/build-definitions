# Migration from 0.3 to 0.4

Version 0.4:

* Changes the default SBOM format from CycloneDX to SPDX.

## Action from users

In order for a typical Konflux pipeline to work well with SPDX, all the tasks
that handle SBOMs must be SPDX-ready. Relevant tasks and required versions:

* `prefetch-dependencies >= 0.2`
* `source-build >= 0.2`
* `deprecated-image-check >= 0.5`

> Note: the same version constraints apply even if you use the `*-oci-ta` variants
> of these tasks.

If your pipeline uses these tasks, please make sure their versions are high enough.
There's a good chance that the Pull Request which led you to this migration document
has updated every relevant task in your pipelines at once.
