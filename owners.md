# Build Definitions 
## Images shared across Tasks
|  Num   |  Image   | Task(s)  | Count   | 
| -------- | -------- | -------  | ------- | 
| 1 | quay.io/openshift-pipeline/openshift-pipelines-cli-tkn:5.0 | tkn-bundle | 1 | 
| 2 | quay.io/redhat-appstudio/build-definitions-source-image-build-utils | source-build | 1 | 
| 3 | quay.io/redhat-appstudio/buildah:v1.31.0 | build-image-manifest, buildah, buildah-10gb, buildah-6gb, buildah-8gb, buildah-remote | 6 | 
| 4 | quay.io/redhat-appstudio/cachi2:0.4.0 | buildah, buildah-10gb, buildah-6gb, buildah-8gb, buildah-remote, prefetch-dependencies | 6 | 
| 5 | quay.io/redhat-appstudio/clair-in-ci:v1 | clair-scan | 1 | 
| 6 | quay.io/redhat-appstudio/cosign:v2.1.1 | buildah, buildah-10gb, buildah-6gb, buildah-8gb, buildah-remote, rpm-ostree, s2i-java, s2i-nodejs, show-sbom | 9 | 
| 7 | quay.io/redhat-appstudio/github-app-token | update-infra-deployments | 1 | 
| 8 | quay.io/redhat-appstudio/hacbs-jvm-build-request-processor:127ee0c223a2b56a9bd20a6f2eaeed3bd6015f77 | buildah, buildah-10gb, buildah-6gb, buildah-8gb, buildah-remote, s2i-java | 6 | 
| 9 | quay.io/redhat-appstudio/hacbs-test:v1.1.9 | clair-scan, clamav-scan, deprecated-image-check, fbc-related-image-check, fbc-validation, inspect-image, sast-snyk-check, sbom-json-check, verify-signed-rpms | 9 | 
| 10 | quay.io/redhat-appstudio/multi-platform-runner:01c7670e81d5120347cf0ad13372742489985e5f | buildah-remote, rpm-ostree | 2 | 
| 11 | quay.io/redhat-appstudio/syft:v0.98.0 | buildah, buildah-10gb, buildah-6gb, buildah-8gb, buildah-remote, rpm-ostree, s2i-java, s2i-nodejs | 8 | 
| 12 | quay.io/redhat-appstudio/update-infra-deployments-task-script-image | update-infra-deployments | 1 | 
| 13 | quay.io/redhat-user-workloads/project-sagano-tenant/ostree-builder/ostree-builder-fedora-38:d124414a81d17f31b1d734236f55272a241703d7 | rpm-ostree | 1 | 
| 14 | registry.access.redhat.com/ubi9/buildah:9.1.0-5 | s2i-java, s2i-nodejs | 2 | 
| 15 | registry.access.redhat.com/ubi9/python-39:1-158 | buildah, buildah-10gb, buildah-6gb, buildah-8gb, buildah-remote, rpm-ostree, s2i-java, s2i-nodejs | 8 | 
| 16 | registry.access.redhat.com/ubi9/ubi-minimal:9.3-1361.1699548032 | slack-webhook-notification, summary | 2 | 
| 17 | registry.redhat.io/ocp-tools-4-tech-preview/source-to-image-rhel8 | s2i-java, s2i-nodejs | 2 | 
| 18 | registry.redhat.io/openshift-pipelines/pipelines-git-init-rhel8:v1.8.2-8 | update-infra-deployments | 1 | 
| 19 | registry.redhat.io/openshift4/ose-cli:4.13 | init | 1 | 
| 20 | registry.redhat.io/ubi9:9.2-696 | git-clone | 1 | 
## Tasks and Owners 
| Num |  Task  | Owner  |
|  ------- |  ------- | ------- |
|     1	| build-image-manifest | Stonesoup Build Team | 
|     2	| buildah | Stonesoup Build Team | 
|     3	| buildah-10gb | Stonesoup Build Team | 
|     4	| buildah-6gb | Stonesoup Build Team | 
|     5	| buildah-8gb | Stonesoup Build Team | 
|     6	| buildah-remote | Stonesoup Build Team | 
|     7	| clair-scan | Stonesoup Test Team | 
|     8	| clamav-scan | Stonesoup Test Team | 
|     9	| deprecated-image-check | Stonesoup Test Team | 
|    10	| fbc-related-image-check | Stonesoup Test Team | 
|    11	| fbc-validation | Stonesoup Test Team | 
|    12	| generate-odcs-compose | No-Owners-File | 
|    13	| git-clone | Stonesoup Build Team | 
|    14	| init | Stonesoup Build Team | 
|    15	| inspect-image | Stonesoup Test Team | 
|    16	| prefetch-dependencies | Stonesoup Build Team | 
|    17	| rpm-ostree | No-Owners-File | 
|    18	| s2i-java | Stonesoup Build Team | 
|    19	| s2i-nodejs | Stonesoup Build Team | 
|    20	| sast-snyk-check | Stonesoup Test Team | 
|    21	| sbom-json-check | Stonesoup Test Team | 
|    22	| show-sbom | Stonesoup Build Team | 
|    23	| slack-webhook-notification | Stonesoup Build Team | 
|    24	| source-build | Stonesoup Build Team | 
|    25	| summary | Stonesoup Build Team | 
|    26	| tkn-bundle | Stonesoup Enterprise Contract Team | 
|    27	| update-infra-deployments | Stonesoup Build Team | 
|    28	| verify-signed-rpms | No-Owners-File | 
