FROM quay.io/enterprise-contract/ec-cli:snapshot AS ec-image
FROM registry.access.redhat.com/ubi9/ubi

COPY --from=ec-image /usr/local/bin/ec_linux_amd64.gz /usr/bin/ec.gz
RUN gunzip /usr/bin/ec.gz && chmod +x /usr/bin/ec

RUN curl -L https://github.com/jqlang/jq/releases/download/jq-1.7.1/jq-linux-amd64 -o /usr/bin/jq && chmod +x /usr/bin/jq
RUN curl -L https://github.com/mikefarah/yq/releases/download/v4.25.1/yq_linux_amd64 -o /usr/bin/yq && chmod +x /usr/bin/yq
RUN curl -L https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/ocp/latest-4.10/openshift-client-linux.tar.gz | tar -xz -C /usr/bin/
RUN curl -L https://github.com/sigstore/cosign/releases/download/v2.4.1/cosign-linux-amd64 -o /usr/bin/cosign && chmod +x /usr/bin/cosign
RUN curl -L https://github.com/tektoncd/cli/releases/download/v0.32.2/tkn_0.32.2_Linux_x86_64.tar.gz | tar -xz --no-same-owner -C /usr/bin/ tkn
RUN curl -L https://github.com/sigstore/rekor/releases/download/v0.5.0/rekor-cli-linux-amd64 -o /usr/bin/rekor-cli && chmod +x /usr/bin/rekor-cli
RUN curl -L https://github.com/open-policy-agent/conftest/releases/download/v0.32.0/conftest_0.32.0_Linux_x86_64.tar.gz | tar -xz --no-same-owner -C /usr/bin
RUN curl -L https://github.com/cli/cli/releases/download/v2.60.1/gh_2.60.1_linux_amd64.tar.gz | tar -xz  -C /usr/bin --wildcards "gh_*/bin/gh" --strip-components=2 --no-same-owner


# 1.2.0 is the minimum required version
RUN curl -L https://github.com/oras-project/oras/releases/download/v1.2.1/oras_1.2.1_linux_amd64.tar.gz | \
    tar -xz --no-same-owner -C /usr/bin oras

RUN dnf -y --setopt=tsflags=nodocs install \
    git \
    skopeo \
    make \
    golang \
    zip \
    && dnf clean all

COPY util-scripts /appstudio-utils/util-scripts
