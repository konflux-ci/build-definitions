FROM registry.access.redhat.com/ubi8/ubi

RUN curl -L https://github.com/mikefarah/yq/releases/download/v4.15.1/yq_linux_amd64 -o /usr/bin/yq && chmod +x /usr/bin/yq
RUN curl -L https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/ocp/latest-4.9/openshift-client-linux.tar.gz | tar -xz -C /usr/bin/
RUN dnf -y --setopt=tsflags=nodocs install \
    jq \
    skopeo && \
    dnf clean all
COPY util-scripts /appstudio-utils/util-scripts
