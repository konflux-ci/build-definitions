# Changelog

<!-- Format guidelines: https://keepachangelog.com/en/1.1.0/#how -->

## Unreleased

<!--
When you make changes without bumping the version right away, document them here.
If that's not something you ever plan to do, consider removing this section.
-->

*Nothing yet.*

## 0.3.1

### Added

- In addition to the `cachi2.env` file, the output directory will also have
  a `prefetch.env` file.
  - Both files have the same content, `prefetch.env` is the primary one.
    `cachi2.env` stays for now, for backwards compatibility with existing Tasks.
- In addition to the `*.env` files, the output directory will also have
  a `prefetch-env.json` file.
  - This will enable future versions of the buildah Task to inject prefetch environment
    variables without any invasive editing of the containerfile.

## 0.3

- Removed deprecated `dev-package-managers` parameter.
- Switched from bash implementation to Konflux Build CLI.
