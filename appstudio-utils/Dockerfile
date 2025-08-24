FROM quay.io/enterprise-contract/cli:latest AS ec-image
RUN ARCH=$(uname -m) && \
    if [ "$ARCH" = "x86_64" ]; then ARCH="amd64"; elif [ "$ARCH" = "aarch64" ]; then ARCH="arm64"; fi && \
    cp /usr/local/bin/ec_linux_${ARCH}.gz /tmp/ec.gz
FROM quay.io/konflux-ci/buildah-task:latest@sha256:b82d465a06c926882d02b721cf8a8476048711332749f39926a01089cf85a3f9 AS buildah-task-image
FROM registry.access.redhat.com/ubi9/ubi

COPY --from=ec-image /tmp/ec.gz /usr/bin/ec.gz
RUN gunzip /usr/bin/ec.gz && chmod +x /usr/bin/ec
COPY --from=buildah-task-image /usr/bin/retry /usr/bin/

RUN ARCH=$(uname -m) && \
    if [ "$ARCH" = "x86_64" ]; then \
        GO_ARCH="amd64"; \
    elif [ "$ARCH" = "aarch64" ]; then \
        GO_ARCH="arm64"; \
    fi && \
    curl -L https://github.com/jqlang/jq/releases/download/jq-1.7.1/jq-linux-${GO_ARCH} -o /usr/bin/jq && chmod +x /usr/bin/jq && \
    curl -L https://github.com/mikefarah/yq/releases/download/v4.25.1/yq_linux_${GO_ARCH} -o /usr/bin/yq && chmod +x /usr/bin/yq && \
    curl -L https://mirror.openshift.com/pub/openshift-v4/${ARCH}/clients/ocp/latest-4.13/openshift-client-linux.tar.gz | tar -xz -C /usr/bin/ && \
    curl -L https://github.com/sigstore/cosign/releases/download/v2.4.1/cosign-linux-${GO_ARCH} -o /usr/bin/cosign && chmod +x /usr/bin/cosign && \
    curl -L https://github.com/sigstore/rekor/releases/download/v0.5.0/rekor-cli-linux-${GO_ARCH} -o /usr/bin/rekor-cli && chmod +x /usr/bin/rekor-cli && \
    curl -L https://github.com/cli/cli/releases/download/v2.60.1/gh_2.60.1_linux_${GO_ARCH}.tar.gz | tar -xz  -C /usr/bin --wildcards "gh_*/bin/gh" --strip-components=2 --no-same-owner && \
    curl -L https://github.com/oras-project/oras/releases/download/v1.2.1/oras_1.2.1_linux_${GO_ARCH}.tar.gz | tar -xz --no-same-owner -C /usr/bin oras

RUN ARCH=$(uname -m) && \
    if [ "$ARCH" = "x86_64" ]; then \
        TKN_ARCH="x86_64"; CONFTEST_ARCH="x86_64"; \
    elif [ "$ARCH" = "aarch64" ]; then \
        TKN_ARCH="aarch64"; CONFTEST_ARCH="arm64"; \
    fi && \
    curl -L https://github.com/tektoncd/cli/releases/download/v0.32.2/tkn_0.32.2_Linux_${TKN_ARCH}.tar.gz | tar -xz --no-same-owner -C /usr/bin/ tkn && \
    curl -L https://github.com/open-policy-agent/conftest/releases/download/v0.32.0/conftest_0.32.0_Linux_${CONFTEST_ARCH}.tar.gz | tar -xz --no-same-owner -C /usr/bin

RUN dnf -y --setopt=tsflags=nodocs install \
    git \
    skopeo \
    make \
    golang \
    zip \
    && dnf clean all

COPY util-scripts /appstudio-utils/util-scripts
COPY util-scripts/select-oci-auth.sh /usr/local/bin/select-oci-auth

# Set HOME variable to something else than `/` to avoid 'permission denied' problems when writing files.
ENV HOME=/tekton/home
