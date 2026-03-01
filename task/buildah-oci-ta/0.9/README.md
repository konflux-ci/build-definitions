# buildah-oci-ta task

Buildah task builds source code into a container image and pushes the image into container registry using buildah tool.
In addition, it generates a SBOM file, injects the SBOM file into final container image and pushes the SBOM file as separate image using cosign tool.
When prefetch-dependencies task is activated it is using its artifacts to run build in hermetic environment.

## Parameters
|name|description|default value|required|
|---|---|---|---|
|ACTIVATION_KEY|Name of secret which contains subscription activation key|activation-key|false|
|ADDITIONAL_BASE_IMAGES|Additional base image references to include to the SBOM. Array of image_reference_with_digest strings|[]|false|
|ADDITIONAL_SECRET|Name of a secret which will be made available to the build with 'buildah build --secret' at /run/secrets/$ADDITIONAL_SECRET|does-not-exist|false|
|ADD_CAPABILITIES|Comma separated list of extra capabilities to add when running 'buildah build'|""|false|
|ANNOTATIONS|Additional key=value annotations that should be applied to the image|[]|false|
|ANNOTATIONS_FILE|Path to a file with additional key=value annotations that should be applied to the image|""|false|
|BUILDAH_FORMAT|The format for the resulting image's mediaType. Valid values are oci (default) or docker.|oci|false|
|BUILD_ARGS|Array of --build-arg values ("arg=value" strings)|[]|false|
|BUILD_ARGS_FILE|Path to a file with build arguments, see https://www.mankier.com/1/buildah-build#--build-arg-file|""|false|
|BUILD_TIMESTAMP|Defines the single build time for all buildah builds in seconds since UNIX epoch. Conflicts with SOURCE_DATE_EPOCH.|""|false|
|CACHI2_ARTIFACT|The Trusted Artifact URI pointing to the artifact with the prefetched dependencies.|""|false|
|COMMIT_SHA|The image is built from this commit.|""|false|
|CONTEXT|Path to the directory to use as context.|.|false|
|CONTEXTUALIZE_SBOM|Determines if SBOM will be contextualized.|true|false|
|DOCKERFILE|Path to the Dockerfile to build.|./Dockerfile|false|
|ENTITLEMENT_SECRET|Name of secret which contains the entitlement certificates|etc-pki-entitlement|false|
|ENV_VARS|Array of --env values ("env=value" strings)|[]|false|
|HERMETIC|Determines if build will be executed without network access.|false|false|
|HTTP_PROXY|HTTP/HTTPS proxy to use for the buildah pull and build operations. Will not be passed through to the container during the build process.|""|false|
|ICM_KEEP_COMPAT_LOCATION|Whether to keep compatibility location at /root/buildinfo/ for ICM injection|true|false|
|IMAGE|Reference of the image buildah will produce.||true|
|IMAGE_EXPIRES_AFTER|Delete image tag after specified time. Empty means to keep the image tag. Time values could be something like 1h, 2d, 3w for hours, days, and weeks, respectively.|""|false|
|INHERIT_BASE_IMAGE_LABELS|Determines if the image inherits the base image labels.|true|false|
|LABELS|Additional key=value labels that should be applied to the image|[]|false|
|UNSET_LABELS|Array of label names that should not be inherited from the base image. This is useful to prevent inheriting base image metadata like name, version, description, etc. Common examples: name, version, release, summary, description, io.k8s.description, io.k8s.display-name, com.redhat.component, url, vcs-ref, vcs-type, vendor, io.openshift.tags|[name, version, release, summary, description, io.k8s.description, io.k8s.display-name, com.redhat.component, url, vcs-ref, vcs-type, vendor, io.openshift.tags]|false|
|NO_PROXY|Comma separated list of hosts or domains which should bypass the HTTP/HTTPS proxy.|""|false|
|OMIT_HISTORY|Omit build history information from the resulting image. Improves reproducibility by excluding timestamps and layer metadata.|false|false|
|PREFETCH_INPUT|In case it is not empty, the prefetched content should be made available to the build.|""|false|
|PRIVILEGED_NESTED|Whether to enable privileged mode, should be used only with remote VMs|false|false|
|PROXY_CA_TRUST_CONFIG_MAP_KEY|The name of the key in the ConfigMap that contains the proxy CA bundle data.|ca-bundle.crt|false|
|PROXY_CA_TRUST_CONFIG_MAP_NAME|The name of the ConfigMap to read proxy CA bundle data from.|caching-ca-bundle|false|
|REWRITE_TIMESTAMP|Clamp mtime of all files to at most SOURCE_DATE_EPOCH. Does nothing if SOURCE_DATE_EPOCH is not defined.|false|false|
|SBOM_SKIP_VALIDATION|Flag to enable or disable SBOM validation before save. Validation is optional - use this if you are experiencing performance issues.|true|false|
|SBOM_SOURCE_SCAN_ENABLED|Flag to enable or disable SBOM generation from source code. The scanner of the source code is enabled only for non-hermetic builds and can be disabled if the SBOM_SYFT_SELECT_CATALOGERS can't turn off catalogers that cause false positives on source code scanning.|true|false|
|SBOM_SYFT_SELECT_CATALOGERS|Extra option to customize Syft's default catalogers when generating SBOMs. The value corresponds to Syft's CLI flag --select-catalogers. The details about available catalogers can be found here: https://github.com/anchore/syft/wiki/Package-Cataloger-Selection|""|false|
|SBOM_TYPE|Select the SBOM format to generate. Valid values: spdx, cyclonedx. Note: the SBOM from the prefetch task - if there is one - must be in the same format.|spdx|false|
|SKIP_INJECTIONS|Don't inject a content-sets.json or a labels.json file. This requires that the canonical Containerfile takes care of this itself.|false|false|
|SKIP_SBOM_GENERATION|Skip SBOM-related operations. This will likely cause EC policies to fail if enabled|false|false|
|SKIP_UNUSED_STAGES|Whether to skip stages in Containerfile that seem unused by subsequent stages|true|false|
|SOURCE_ARTIFACT|The Trusted Artifact URI pointing to the artifact with the application source code.||true|
|SOURCE_DATE_EPOCH|Timestamp in seconds since Unix epoch for reproducible builds. Sets image created time and SOURCE_DATE_EPOCH build arg. Conflicts with BUILD_TIMESTAMP.|""|false|
|SOURCE_URL|The image is built from this URL.|""|false|
|SQUASH|Squash all new and previous layers added as a part of this build, as per --squash|false|false|
|STORAGE_DRIVER|Storage driver to configure for buildah|overlay|false|
|TARGET_STAGE|Target stage in Dockerfile to build. If not specified, the Dockerfile is processed entirely to (and including) its last stage.|""|false|
|TLSVERIFY|Verify the TLS on the registry endpoint (for push/pull to a non-TLS registry)|true|false|
|WORKINGDIR_MOUNT|Mount the current working directory into the build using --volume $PWD:/$WORKINGDIR_MOUNT. Note that the $PWD will be the context directory for the build (see the CONTEXT param).|""|false|
|YUM_REPOS_D_FETCHED|Path in source workspace where dynamically-fetched repos are present|fetched.repos.d|false|
|YUM_REPOS_D_SRC|Path in the git repository in which yum repository files are stored|repos.d|false|
|YUM_REPOS_D_TARGET|Target path on the container in which yum repository files should be made available|/etc/yum.repos.d|false|
|caTrustConfigMapKey|The name of the key in the ConfigMap that contains the CA bundle data.|ca-bundle.crt|false|
|caTrustConfigMapName|The name of the ConfigMap to read CA bundle data from.|trusted-ca|false|

## Results
|name|description|
|---|---|
|IMAGE_DIGEST|Digest of the image just built|
|IMAGE_REF|Image reference of the built image|
|IMAGE_URL|Image repository and tag where the built image was pushed|
|SBOM_BLOB_URL|Reference of SBOM blob digest to enable digest-based verification from provenance|


## Additional info
