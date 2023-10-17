# image: build-definitions-source-image-utils:latest
FROM registry.access.redhat.com/ubi9/ubi:9.2-722
ARG release_url=https://github.com/containers/BuildSourceImage/archive/refs/tags/v0.2.0.tar.gz
ARG bin_dir=/opt/BuildSourceImage
RUN dnf update -y && dnf install -y python3.11 git jq skopeo file tar && dnf clean all
RUN mkdir -p /opt/BuildSourceImage/ &&  \
    curl -s -L $release_url | tar --extract -C $bin_dir -z --strip-components=1 \
    BuildSourceImage-0.2.0/BuildSourceImage.sh && \
    mv $bin_dir/BuildSourceImage.sh $bin_dir/bsi

