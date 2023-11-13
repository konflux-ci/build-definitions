#!/bin/bash

SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
IMG=quay.io/redhat-user-workloads/rhtap-build-tenant/multi-arch-controller/multi-arch-controller:taskgen-57750ec21414607fa20acdef7984f32bbb7730af

podman run -v "$SCRIPTDIR"/..:/data $IMG \
       --buildah-task=/data/task/buildah/0.1/buildah.yaml \
       --remote-task=/data/task/buildah-remote/0.1/buildah-remote.yaml
