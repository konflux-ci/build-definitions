FROM registry.access.redhat.com/ubi8/ubi-minimal  
RUN microdnf install  wget 
RUN wget https://github.com/mikefarah/yq/releases/download/v4.15.1/yq_linux_amd64 -O /usr/bin/yq 
RUN chmod +x /usr/bin/yq
RUN microdnf install  jq 
RUN microdnf install  skopeo 
RUN mkdir /appstudio-utils
COPY util-scripts   /appstudio-utils/util-scripts 
RUN chmod +x /appstudio-utils/util-scripts/*.sh