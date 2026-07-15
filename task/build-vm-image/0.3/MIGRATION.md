# Migration from 0.2 to 0.3

## What changed

The OCI artifact type for qcow2 disk images has been corrected from
`application/vnd.diskimage.qcow2.gzip` to `application/vnd.diskimage.qcow2`.

The previous artifact type was wrong - the task never gzip-compressed the
qcow2 payload. The qcow2 format uses its own internal compression, so
the `.gzip` suffix was misleading. Consumers that trusted the artifact
type and attempted to gunzip the payload would get an error.

## Action from users

If you have automation or tooling that matches on the OCI artifact type
`application/vnd.diskimage.qcow2.gzip` (e.g. filtering manifests,
pulling artifacts by type, or content verification), update it to match
`application/vnd.diskimage.qcow2` instead.

If you never inspect the artifact type, no action is required.
