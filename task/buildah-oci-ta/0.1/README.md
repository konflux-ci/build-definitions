# buildah-oci-ta task

Buildah task builds source code into a container image and pushes the image into container registry using buildah tool.
In addition it generates a SBOM file, injects the SBOM file into final container image and pushes the SBOM file as separate image using cosign tool.
When [Java dependency rebuild](https://redhat-appstudio.github.io/docs.stonesoup.io/Documentation/main/cli/proc_enabled_java_dependencies.html) is enabled it triggers rebuilds of Java artifacts.
When prefetch-dependencies task was activated it is using its artifacts to run build in hermetic environment.

## Parameters
|name|description|default value|required|
|---|---|---|---|
|ADDITIONAL_SECRET|Name of a secret which will be made available to the build with 'buildah build --secret' at /run/secrets/$ADDITIONAL_SECRET|does-not-exist|false|
|ADD_CAPABILITIES|Comma separated list of extra capabilities to add when running 'buildah build'|""|false|
|BUILD_ARGS|Array of --build-arg values ("arg=value" strings)|[]|false|
|BUILD_ARGS_FILE|Path to a file with build arguments, see https://www.mankier.com/1/buildah-build#--build-arg-file|""|false|
|CACHI2_ARTIFACT|The Trusted Artifact URI pointing to the artifact with the prefetched dependencies.|""|false|
|COMMIT_SHA|The image is built from this commit.|""|false|
|CONTEXT|Path to the directory to use as context.|.|false|
|DOCKERFILE|Path to the Dockerfile to build.|./Dockerfile|false|
|DOCKER_AUTH|unused, should be removed in next task version|""|false|
|ENTITLEMENT_SECRET|Name of secret which contains the entitlement certificates|etc-pki-entitlement|false|
|HERMETIC|Determines if build will be executed without network access.|false|false|
|IMAGE|Reference of the image buildah will produce.||true|
|IMAGE_EXPIRES_AFTER|Delete image tag after specified time. Empty means to keep the image tag. Time values could be something like 1h, 2d, 3w for hours, days, and weeks, respectively.|""|false|
|PREFETCH_INPUT|In case it is not empty, the prefetched content should be made available to the build.|""|false|
|SOURCE_ARTIFACT|The Trusted Artifact URI pointing to the artifact with the application source code.||true|
|SQUASH|Squash new layers added as a part of this build, as per --squash|false|false|
|SQUASH_ALL|Squash all new and previous layers added as a part of this build, as per --squash-all|false|false|
|TARGET_STAGE|Target stage in Dockerfile to build. If not specified, the Dockerfile is processed entirely to (and including) its last stage.|""|false|
|TLSVERIFY|Verify the TLS on the registry endpoint (for push/pull to a non-TLS registry)|true|false|
|YUM_REPOS_D_FETCHED|Path in source workspace where dynamically-fetched repos are present|fetched.repos.d|false|
|YUM_REPOS_D_SRC|Path in the git repository in which yum repository files are stored|repos.d|false|
|YUM_REPOS_D_TARGET|Target path on the container in which yum repository files should be made available|/etc/yum.repos.d|false|
|caTrustConfigMapKey|The name of the key in the ConfigMap that contains the CA bundle data.|ca-bundle.crt|false|
|caTrustConfigMapName|The name of the ConfigMap to read CA bundle data from.|trusted-ca|false|

## Results
|name|description|
|---|---|
|BASE_IMAGES_DIGESTS|Digests of the base images used for build|
|IMAGE_DIGEST|Digest of the image just built|
|IMAGE_URL|Image repository where the built image was pushed|
|JAVA_COMMUNITY_DEPENDENCIES|The Java dependencies that came from community sources such as Maven central.|
|SBOM_JAVA_COMPONENTS_COUNT|The counting of Java components by publisher in JSON format|

