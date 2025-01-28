# sast-coverity-check-oci-ta task

Scans source code for security vulnerabilities, including common issues such as SQL injection, cross-site scripting (XSS), and code injection attacks using Coverity.

## Parameters
|name|description|default value|required|
|---|---|---|---|
|ACTIVATION_KEY|Name of secret which contains subscription activation key|activation-key|false|
|ADDITIONAL_SECRET|Name of a secret which will be made available to the build with 'buildah build --secret' at /run/secrets/$ADDITIONAL_SECRET|does-not-exist|false|
|ADD_CAPABILITIES|Comma separated list of extra capabilities to add when running 'buildah build'|""|false|
|BUILD_ARGS|Array of --build-arg values ("arg=value" strings)|[]|false|
|BUILD_ARGS_FILE|Path to a file with build arguments, see https://www.mankier.com/1/buildah-build#--build-arg-file|""|false|
|CACHI2_ARTIFACT|The Trusted Artifact URI pointing to the artifact with the prefetched dependencies.|""|false|
|COMMIT_SHA|The image is built from this commit.|""|false|
|CONTEXT|Path to the directory to use as context.|.|false|
|COV_ANALYZE_ARGS|Arguments to be appended to the cov-analyze command|--enable HARDCODED_CREDENTIALS --security --concurrency --spotbugs-max-mem=4096|false|
|COV_LICENSE|Name of secret which contains the Coverity license|cov-license|false|
|DOCKERFILE|Path to the Dockerfile to build.|./Dockerfile|false|
|ENTITLEMENT_SECRET|Name of secret which contains the entitlement certificates|etc-pki-entitlement|false|
|HERMETIC|Determines if build will be executed without network access.|false|false|
|IMAGE|Reference of the image buildah will produce.||true|
|IMAGE_EXPIRES_AFTER|Delete image tag after specified time. Empty means to keep the image tag. Time values could be something like 1h, 2d, 3w for hours, days, and weeks, respectively.|""|false|
|IMP_FINDINGS_ONLY|Report only important findings. Default is true. To report all findings, specify "false"|true|false|
|KFP_GIT_URL|URL from repository to download known false positives files|""|false|
|LABELS|Additional key=value labels that should be applied to the image|[]|false|
|PREFETCH_INPUT|In case it is not empty, the prefetched content should be made available to the build.|""|false|
|PRIVILEGED_NESTED|Whether to enable privileged mode|false|false|
|PROJECT_NAME||""|false|
|RECORD_EXCLUDED||false|false|
|SBOM_TYPE|Select the SBOM format to generate. Valid values: spdx, cyclonedx. Note: the SBOM from the prefetch task - if there is one - must be in the same format.|cyclonedx|false|
|SKIP_SBOM_GENERATION|Skip SBOM-related operations. This will likely cause EC policies to fail if enabled|false|false|
|SKIP_UNUSED_STAGES|Whether to skip stages in Containerfile that seem unused by subsequent stages|true|false|
|SOURCE_ARTIFACT|The Trusted Artifact URI pointing to the artifact with the application source code.||true|
|SQUASH|Squash all new and previous layers added as a part of this build, as per --squash|false|false|
|STORAGE_DRIVER|Storage driver to configure for buildah|vfs|false|
|TARGET_STAGE|Target stage in Dockerfile to build. If not specified, the Dockerfile is processed entirely to (and including) its last stage.|""|false|
|TLSVERIFY|Verify the TLS on the registry endpoint (for push/pull to a non-TLS registry)|true|false|
|YUM_REPOS_D_FETCHED|Path in source workspace where dynamically-fetched repos are present|fetched.repos.d|false|
|YUM_REPOS_D_SRC|Path in the git repository in which yum repository files are stored|repos.d|false|
|YUM_REPOS_D_TARGET|Target path on the container in which yum repository files should be made available|/etc/yum.repos.d|false|
|caTrustConfigMapKey|The name of the key in the ConfigMap that contains the CA bundle data.|ca-bundle.crt|false|
|caTrustConfigMapName|The name of the ConfigMap to read CA bundle data from.|trusted-ca|false|
|image-url|||true|

## Results
|name|description|
|---|---|
|TEST_OUTPUT|Tekton task test output.|

