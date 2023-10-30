FROM registry.access.redhat.com/ubi9/ubi:9.2-722
ARG bsi_source=https://github.com/containers/BuildSourceImage/archive/refs/tags/v0.2.0.tar.gz
ARG bin_dir=/opt/BuildSourceImage
ARG patch0=0001-cleanup-directory-with-all-rpms-which-isn-t-used-any.patch
ARG patch1=0001-Increase-counter-as-numeric-rather-than-string.patch
RUN dnf update -y && dnf install -y python3.11 git jq skopeo file tar && dnf clean all
ADD $patch0 $patch1 /tmp/patches
ADD app/source_build.py app/requirements.txt /opt/source_build/
RUN mkdir -p $bin_dir &&  \
    curl -s -L $bsi_source | tar --extract -C $bin_dir -z --strip-components=1 BuildSourceImage-0.2.0/BuildSourceImage.sh && \
    cd $bin_dir && \
    git apply --allow-empty BuildSourceImage.sh /tmp/patches/$patch0 && \
    git apply --allow-empty BuildSourceImage.sh /tmp/patches/$patch1 && \
    rm -r /tmp/patches && \
    mv BuildSourceImage.sh bsi && \
    cd /opt/source_build && python3.11 -m venv appenv && \
    /opt/source_build/appenv/bin/python3 -m pip install --no-cache-dir -r /opt/source_build/requirements.txt
