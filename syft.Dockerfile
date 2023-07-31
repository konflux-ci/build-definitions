FROM registry.access.redhat.com/ubi8:8.8-1009

RUN dnf install -y https://github.com/anchore/syft/releases/download/v0.85.0/syft_0.85.0_linux_amd64.rpm && dnf clean all
