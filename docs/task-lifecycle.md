# Task Lifecycle Policy

This document defines the lifecycle policy for versioned Tekton tasks maintained
in this repository. It exists to help contributors quickly identify which task
versions are in scope for a given change, and to establish clear criteria for
deprecation, archival, and removal.

---

## Task Lifecycle Stages

Every task version passes through the following stages in order:

```
Active ──► Deprecated ──► Archived ──► Removed
```

### Active

A task version is **active** when it is the current, supported version of that task.

- Lives under `task/<task-name>/<version>/`
- Receives bug fixes, security patches, and feature updates
- Referenced by Konflux pipelines
- Has no `build.appstudio.redhat.com/expires-on` label, **or** the label date is
  in the future and has not yet been announced as deprecated

### Deprecated

A task version is **deprecated** when a newer version supersedes it and the old
version is scheduled for archival.

- Still lives under `task/<task-name>/<version>/`
- **Must** carry the `build.appstudio.redhat.com/expires-on` label with an RFC 3339
  timestamp indicating when it will be archived (see [Label Usage](#label-usage))
- Receives security patches only — no new features
- Pipelines referencing this version should be migrated to the newer version before
  the expiry date

### Archived

A task version is **archived** when it has passed its `expires-on` date and has been
moved out of the active `task/` tree.

- Moved from `task/<task-name>/<version>/` to `archived-tasks/<task-name>/<version>/`
- A symlink at the original path preserves compatibility with any pipelines that
  still reference the old location (see [Symlinks](#symlinks-and-compatibility))
- No further patches are applied
- Users are expected to migrate away from archived versions

### Removed

A task version is **removed** when it is deleted from the repository entirely,
including its entry in `archived-tasks/`.

- See [When Archived Tasks Can Be Removed](#when-archived-tasks-can-be-removed)

---

## Support Scope of Task Versions

At any given time this repository maintains:

| Versions kept | Policy |
|---------------|--------|
| **Latest version** | Always active; receives all updates |
| **Previous N−1 version** | Active or deprecated; receives security patches until its `expires-on` date |
| **Older versions** | Deprecated with an `expires-on` label; archived after expiry |

As a rule of thumb, a deprecated version is given **at least 3 months** before
archival to allow downstream pipeline owners time to migrate.

> **For contributors performing repository-wide changes:** only `task/` versions
> *without* an `expires-on` label, or with an `expires-on` date still in the future
> **and** no announced migration path, are in scope. Versions with a past `expires-on`
> date can be treated as archived regardless of their physical location.

---

## Moving a Task from `task/` to `archived-tasks/`

When a task version's `expires-on` date is reached:

1. **Move** the version directory:
   ```bash
   git mv task/<task-name>/<version>/ archived-tasks/<task-name>/<version>/
   ```

2. **Create a symlink** at the original location so existing bundle references
   continue to resolve:
   ```bash
   ln -s ../../archived-tasks/<task-name>/<version> task/<task-name>/<version>
   git add task/<task-name>/<version>
   ```

3. **Commit** with a message following the convention:
   ```
   chore(<task-name>): archive version <version>
   ```

4. **Do not** remove the `archived-tasks/` entry at this point — see
   [When Archived Tasks Can Be Removed](#when-archived-tasks-can-be-removed).

---

## Symlinks and Compatibility

The symlink kept at `task/<task-name>/<version>` after archival serves one purpose:
**OCI bundle references in existing pipelines continue to resolve** during the build
and push process that assembles Tekton catalog bundles from this repository.

Once no active Konflux pipeline references the archived version — verified by
checking `pipelines/` and any known external consumers — the symlink and the
`archived-tasks/` entry can be removed together.

---

## Label Usage

### `build.appstudio.redhat.com/expires-on`

Every task version that is deprecated **must** define this annotation in its
`metadata.annotations` block. The value must be an RFC 3339 UTC timestamp.

```yaml
apiVersion: tekton.dev/v1
kind: Task
metadata:
  name: <task-name>
  labels:
    app.kubernetes.io/version: "0.8.1"
  annotations:
    build.appstudio.redhat.com/expires-on: "2026-06-30T00:00:00Z"
    build.appstudio.redhat.com/expiration-msg: >-
      This task version is deprecated. Please migrate to version 0.9.
      See task/buildah/0.9/MIGRATION.md for instructions.
    tekton.dev/pipelines.minVersion: "0.12.1"
    tekton.dev/tags: "image-build, konflux"
```

**Rules:**

- `expires-on` is **required** on all deprecated task versions
- `expiration-msg` is **strongly recommended** — it gives pipeline owners
  actionable migration guidance without having to look up the CHANGELOG
- The timestamp must be at least **3 months in the future** from the date
  the deprecation PR is merged, unless the version has a critical security
  issue requiring faster removal
- Both annotations belong in `metadata.annotations`, not `metadata.labels`

### `app.kubernetes.io/version`

All task versions must carry this label and its value must match the version
directory (e.g. `"0.9.1"` in the `0.9/` directory). This is enforced by
`hack/check-task-version-labels.sh` in CI.

---

## When Archived Tasks Can Be Removed

An archived task version (living in `archived-tasks/`) may be **permanently
deleted** when **all** of the following conditions are met:

1. Its `expires-on` date has passed.
2. No pipeline in `pipelines/` references the version.
3. No known external Konflux consumer (confirmed via the build team) references
   the OCI bundle for that version.
4. The symlink at `task/<task-name>/<version>` has been present for at least
   **one full release cycle** after the `expires-on` date, giving downstream
   consumers time to detect and resolve the deprecation.

To remove, delete both the `archived-tasks/` directory and the `task/` symlink
in a single commit:

```bash
git rm -r archived-tasks/<task-name>/<version>/
git rm task/<task-name>/<version>
git commit -m "chore(<task-name>): remove archived version <version>"
```

---

## Summary Checklist for Contributors

When deprecating a task version:

- [ ] Add `build.appstudio.redhat.com/expires-on` annotation with a date ≥ 3
      months from today
- [ ] Add `build.appstudio.redhat.com/expiration-msg` annotation with migration
      instructions
- [ ] Ensure the newer version has a `MIGRATION.md` describing what changed
- [ ] Update the task `CHANGELOG.md`

When archiving a task version (after `expires-on` passes):

- [ ] `git mv task/<name>/<version>/ archived-tasks/<name>/<version>/`
- [ ] Create symlink at `task/<name>/<version>` pointing to archived location
- [ ] Commit with `chore(<name>): archive version <version>`

When removing an archived task version:

- [ ] Confirm no active pipeline references the version
- [ ] Delete `archived-tasks/<name>/<version>/` and `task/<name>/<version>` symlink
- [ ] Commit with `chore(<name>): remove archived version <version>`
