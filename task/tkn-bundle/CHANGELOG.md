# Changelog

<!-- Format guidelines: https://keepachangelog.com/en/1.1.0/#how -->

## Unreleased

<!--
When you make changes without bumping the version right away, document them here.
If that's not something you ever plan to do, consider removing this section.
-->

## 0.2.4

### Removed

- Unused `build-source-image` pipeline parameter from tekton-bundle-builder
  pipelines via migration. Source image builds are not applicable to tekton
  bundle builds.

## 0.2.3

### Removed

- The check that fails the build if the migration script for the current task
  version already exists in the registry and has a different checksum.
  - The check aimed to prevent a situation where pipeline-migration-tool would
    see two different migration scripts for the same task version (pmt aborts
    the entire migration resolution process in that case).
  - What the check achieved in practice is that after opening a PR that includes
    a migration script, it becomes impossible to change anything in that script,
    because tkn-bundle already pushed the initial iteration.
  - It's unnecessary do this check for PR builds, because only the *released*
    bundles and their migration scripts are relevant.
  - The check-task-migration GH workflow, which should be present in all Konflux
    Task repos, already protects against modifying migration scripts that have
    been merged into the target branch. This prevents a released migration script
    from changing, making this check entirely unnecessary.

## 0.2.2

### Added

Version 0.2.2 now supports updating specific step images instead of every step.

