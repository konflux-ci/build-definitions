# Migration from 0.1 to 0.2

Version 0.2:

* Changes the default SBOM format from CycloneDX to SPDX.

## Action from users

A typical pipeline based around the `oci-copy` task doesn't include any other
SBOM-handling tasks. No action needed.

For completeness, the tasks that *could* be relevant and their SPDX-ready versions:

* `source-build >= 0.2`
* `deprecated-image-check >= 0.5`

> Note: the same version constraints apply even if you use the `*-oci-ta` variants
> of these tasks.

If your pipeline uses these tasks, please make sure their versions are high enough.
There's a good chance that the Pull Request which led you to this migration document
has updated every relevant task in your pipelines at once.
