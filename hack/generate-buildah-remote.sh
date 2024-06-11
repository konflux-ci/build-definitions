#!/bin/bash

SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

cd $SCRIPTDIR/../remote-task-generator
go build -o /tmp/generator ./main.go


/tmp/generator --buildah-task=$SCRIPTDIR/../task/buildah/0.1/buildah.yaml \
       --remote-task=$SCRIPTDIR/../task/buildah-remote/0.1/buildah-remote.yaml
/tmp/generator --buildah-task=$SCRIPTDIR/../task/buildah-oci-ta/0.1/buildah-oci-ta.yaml \
       --remote-task=$SCRIPTDIR/../task/buildah-remote-oci-ta/0.1/buildah-remote-oci-ta.yaml
