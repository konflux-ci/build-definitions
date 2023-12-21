#!/bin/bash

SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
IMG=quay.io/redhat-user-workloads/rhtap-build-tenant/multi-arch-controller/multi-arch-controller:taskgen-b160582a1c1eabe4beea5006ca09c2932e12d060

podman run -v "$SCRIPTDIR"/..:/data:Z $IMG \
       --buildah-task=/data/task/buildah/0.1/buildah.yaml \
       --remote-task=/data/task/buildah-remote/0.1/buildah-remote.yaml
