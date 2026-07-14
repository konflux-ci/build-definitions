# Changelog

<!-- Format guidelines: https://keepachangelog.com/en/1.1.0/#how -->

## Unreleased

<!--
When you make changes without bumping the version right away, document them here.
If that's not something you ever plan to do, consider removing this section.
-->

*Nothing yet.*

## 0.10.5

### Added

- Added a new parameter RHSM_MOUNT_CA_CERTS to allow setting [konflux-build-cli]'s
  `--rhsm-mount-ca-certs` option.

## 0.10.4

### Fixed

- Restores the `/cachi2/cachi2.env` mount that version 0.10.3 removed.
  Despite being an undocumented implementation detail, some builds use
  the presence of this file as an indicator that the build is hermetic.
  Enable them to do so for the time being.

## 0.10.3

### Added

- Added new parameter ALLOW_CROSS_PLATFORM_IMAGES to allow usage of parent images
  which don't match build host architecture.

### Changed

- When used with prefetch-dependencies >= 0.3.1, no longer edits RUN instructions
  in order to set the prefetch environment variables. Instead, sets the variables
  using buildah `--mount` + `--secret` flags. Details in [konflux-build-cli#151].
  Fixes [#1200].
  - As a side effect, also no longer mounts the `/cachi2/cachi2.env` file,
    whose only purpose was to enable the automatic setting of prefetch variables.

[konflux-build-cli#151]: https://github.com/konflux-ci/konflux-build-cli/pull/151

## 0.10.2

### Fixed

- The injected `labels.json` file will now better match the actual image labels
  in cases when the containerfile includes quoted `LABEL` values. This is a result
  of [dockerfile-json#16].

[dockerfile-json#16]: https://github.com/konflux-ci/dockerfile-json/pull/16

## 0.10.1

### Changed

- Updated the image that runs the `build` and `push` steps.
  Notably, the new image comes with Buildah `v1.44.0`.

## 0.10

This version introduces [konflux-build-cli]. The `build` step replaces most of the Bash with
`konflux-build-cli image build`. Other steps still use Bash, this will change soon.

We expect version 0.10 to behave the same as version 0.9 for the vast majority
of use cases. All known (minor) differences documented below.

### Added

- The `vcs-url` label. Previously, the task would inject the following vcs-related labels:
  - `org.opencontainers.image.revision` and its [legacy counterpart][projectatomic-labels],
    `vcs-ref`
  - `org.opencontainers.image.source` and nothing else
    - Version 0.10 adds the missing legacy counterpart, `vcs-url`

### Changed

- The precedence of default annotations (those injected by the task automatically)
  - Before: `ANNOTATIONS_FILE` < `ANNOTATIONS` < default annotations
  - Now: default annotations < `ANNOTATIONS_FILE` < `ANNOTATIONS`
- When handling the `YUM_REPOS_D_SRC` and `YUM_REPOS_D_FETCHED` directories,
  injects only regular files into `/etc/yum.repos.d`. Previously, the task would
  inject the directories as a whole. `/etc/yum.repos.d` is a flat structure, so
  the task now injects only regular files to avoid injecting unexpected content.
- Prefetch integration:
  - Looks for both `prefetch.env` and `cachi2.env` in the prefetch dir (in this order).
    Version 0.3.1 of the prefetch task added `prefetch.env` and a future version
    will remove `cachi2.env`.
  - Doesn't rely specifically on `cachi2.repo` files to enable RPM integration,
    just needs any `*.repo` file at the expected path.
  - In case the `YUM_REPOS_D_SRC` or `YUM_REPOS_D_FETCHED` directories contain
    a repo file with the same name as the repo file from Hermeto, the Hermeto
    repo takes precedence. Previously, `YUM_REPOS_*` would take precedence.
  - Doesn't copy the prefetch files to `/tmp`, instead copies them to a directory
    on the same filesystem as the original files. This uses copy-on-write and avoids
    duplicating the underlying data.
- Red Hat subscription-manager integration:
  - Will mount the RHSM CA certificates into the build in two cases:
    - When using `ACTIVATION_KEY` and the containerfile doesn't include
      `subscription-manager register` (same as before)
    - When using `ENTITLEMENT_SECRET` (not done before and should have been)
  - When mounting RHSM CA certificates, mounts the whole `/etc/rhsm/ca` directory
    instead of mounting a specific file. This closes [#1621].

### Fixed

- Injecting metadata to `/usr/share/buildinfo` and `/root/buildinfo`:
  - Does not write any new files or modify any existing files in the source directory,
    injects the files using a separate build-context.
  - Will log a warning if the `TARGET` param is set and `SKIP_INJECTIONS=false`
    (using `TARGET` disables metadata injection anyway). Metadata injection never
    worked with a non-default target, version 0.10 just adds the warning.
  - Injecting `labels.json`:
    - Will skip LABEL instructions in stages that don't affect the labels of the final image.
    - Will correctly omit the `io.buildah.version` label when `SOURCE_DATE_EPOCH` is non-empty.
      Previously, `labels.json` would always include `io.buildah.version`.
- Pre-pulling base images for hermetic builds and base-arch verification (see [0.9.4](#094)):
  - Also pulls images referenced in `COPY --from=$image` and `RUN --mount=from=$image`.
    Previously, would only pull images referenced as `FROM $image`.
  - Does not pull images for unused stages (unless `SKIP_UNUSED_STAGES=false`).
  - Will skip image references with [transports][containers-transports] that don't
    represent pullable images. Specifically, will only pull transport-less references
    and `docker://` references. Previously, the task would skip `oci-archive:` references
    but fail on any other kind of non-standard reference.
- Modifying the containerfile to set prefetch environment variables in RUN instructions:
  - No longer mangles RUN instructions that use the exec form or a bare here-doc.
    Instead skips the instruction and logs a warning.

    ```dockerfile
    RUN ["echo", "skips exec-form commands"]

    RUN <<EOF
    echo "skips bare heredocs"
    EOF

    RUN bash -e <<EOF
    echo "supports heredocs if they start with something other than the <<marker"
    EOF
    ```

    - This partially fixes [#1200], in the sense that the containerfile at least
      doesn't become broken. The unsupported instructions don't automatically get
      the variables that may be required to make the hermetic build work though.
  - Fixes dozens of small bugs that most users never would have hit. For example,
    version 0.10:
    - Doesn't mangle heredoc lines that look line `RUN` instructions
    - Doesn't inject text into the middle of a string with quoted/escaped whitespace
    - Properly handles [backtick-escaped][dockerfile-escape] containerfiles

[konflux-build-cli]: https://github.com/konflux-ci/konflux-build-cli
[projectatomic-labels]: https://github.com/projectatomic/ContainerApplicationGenericLabels
[containers-transports]: https://www.mankier.com/5/containers-transports
[#1200]: https://github.com/konflux-ci/build-definitions/issues/1200
[dockerfile-escape]: https://docs.docker.com/reference/dockerfile/#escape
[#1621]: https://github.com/konflux-ci/build-definitions/issues/1621

## 0.9.4

### Fixed

- Validate base image architecture before build. The task now fails if a base image
  doesn't match the host architecture, preventing silent emulation builds.

## 0.9.3

### Fixed

- Version bump to stay in sync with buildah-remote. The remote variant now has `--fail` flag
  and error handling on the `curl` call that retrieves the SSH key from the OTP server.

## 0.9.2

### Changed

- The task now sets `org.opencontainers.image.ref.name` annotation in the
  locally stored OCI image index. This is not a user-facing change. It is for
  optimizing buildah-remote task.

## 0.9.1

### Changed

- The buildah image now uses version 1.4.1 of [konflux-ci/task-runner](https://github.com/konflux-ci/task-runner)
  - This version pulls in version 1.42.1 of syft that ensures 'redhat' is used as the namespace for hummingbird rpms

## 0.9

### Removed
- BREAKING: Support for Dockerfile downloading in Konflux Build Pipeline.

## 0.8.3

### Fixed

- Platform build arguments (BUILDPLATFORM, TARGETPLATFORM) now correctly include CPU variant
  for ARM architectures (e.g., `linux/arm/v7` or `linux/arm64/v8` instead of just `linux/arm`
  or `linux/arm64`).

## 0.8.2

### Changed

- The task now makes sure that only RPMs that match the architecture being built are
  passed to the `buildah bud` command. It also removes the same packages from the
  Hermeto SBOM to more accurately represent the build.
  This change should be a noop for this task, but it was added here so that the
  auto-generated `buildah-remote` task would benefit from it.

## 0.8.1

### Added

- The buildah task now supports injecting ENV variables into the dockerfile
  through the `ENV_VARS` array parameter.

## 0.8

### Changed

- The buildah image that runs the task now uses
  [konflux-ci/task-runner](https://github.com/konflux-ci/task-runner) as the base
  image and gets both the `buildah` binary and the relevant configuration from there.
  - This updates the `buildah` version from 1.41.5 to 1.42.2

## 0.7.1

### Added

- Started tracking changes in this file.
