#!/bin/bash

SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
podman run -v "$SCRIPTDIR"/..:/data quay.io/redhat-user-workloads/rhtap-build-tenant/multi-arch-controller/multi-arch-controller:taskgen-221979523603b730feca730aeb9d43f24a3c1e67  --buildah-task=/data/task/buildah/0.1/buildah.yaml --remote-task=/data/task/buildah-remote/0.1/buildah-remote.yaml
