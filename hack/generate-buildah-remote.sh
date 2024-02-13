#!/bin/bash

SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
IMG=quay.io/redhat-user-workloads/rhtap-build-tenant/multi-arch-controller/multi-arch-controller:taskgen-ad9073040af28f18f450db33f539befc5fcc4c73

podman run -v "$SCRIPTDIR"/..:/data:Z $IMG \
       --buildah-task=/data/task/buildah/0.1/buildah.yaml \
       --remote-task=/data/task/buildah-remote/0.1/buildah-remote.yaml
