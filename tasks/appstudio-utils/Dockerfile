FROM registry.access.redhat.com/ubi8/ubi-minimal  
RUN microdnf install  wget 
RUN wget https://github.com/mikefarah/yq/releases/download/v4.15.1/yq_linux_amd64 -O /usr/bin/yq 
RUN chmod +x /usr/bin/yq
RUN microdnf install  jq 
RUN microdnf install  skopeo  
RUN wget https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/ocp/latest-4.9/openshift-client-linux.tar.gz
RUN tar xvf openshift-client-linux.tar.gz
RUN mv oc /usr/bin/oc
RUN mv kubectl /usr/bin/kubectl
RUN chmod +x /usr/bin/oc
RUN chmod +x /usr/bin/kubectl
RUN mkdir /appstudio-utils
COPY util-scripts   /appstudio-utils/util-scripts 
RUN chmod +x /appstudio-utils/util-scripts/*.sh