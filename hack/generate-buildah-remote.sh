#!/bin/bash

SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
IMG=quay.io/redhat-user-workloads/rhtap-build-tenant/multi-arch-controller/multi-arch-controller:taskgen-19eee88a173beaa01ad47511a683fb35927f8f96

podman run -v "$SCRIPTDIR"/..:/data:Z $IMG \
       --buildah-task=/data/task/buildah/0.1/buildah.yaml \
       --remote-task=/data/task/buildah-remote/0.1/buildah-remote.yaml
podman run -v "$SCRIPTDIR"/..:/data:Z $IMG \
       --buildah-task=/data/task/buildah-oci-ta/0.1/buildah-oci-ta.yaml \
       --remote-task=/data/task/buildah-remote-oci-ta/0.1/buildah-remote-oci-ta.yaml
