# sast-coverity-check task

Scans source code for security vulnerabilities, including common issues such as SQL injection, cross-site scripting (XSS), and code injection attacks using Coverity.

## Parameters
|name|description|default value|required|
|---|---|---|---|
|IMAGE|The task will build a container image and tag it locally as $IMAGE, but will not push the image anywhere. Due to the relationship between this task and the buildah task, the parameter is required, but its value is mostly irrelevant.||true|
|DOCKERFILE|Path to the Dockerfile to build.|./Dockerfile|false|
|CONTEXT|Path to the directory to use as context.|.|false|
|TLSVERIFY|Verify the TLS on the registry endpoint (for push/pull to a non-TLS registry)|true|false|
|HERMETIC|Determines if build will be executed without network access.|false|false|
|PREFETCH_INPUT|In case it is not empty, the prefetched content should be made available to the build.|""|false|
|IMAGE_EXPIRES_AFTER|Delete image tag after specified time. Empty means to keep the image tag. Time values could be something like 1h, 2d, 3w for hours, days, and weeks, respectively.|""|false|
|COMMIT_SHA|The image is built from this commit.|""|false|
|YUM_REPOS_D_SRC|Path in the git repository in which yum repository files are stored|repos.d|false|
|YUM_REPOS_D_FETCHED|Path in source workspace where dynamically-fetched repos are present|fetched.repos.d|false|
|YUM_REPOS_D_TARGET|Target path on the container in which yum repository files should be made available|/etc/yum.repos.d|false|
|TARGET_STAGE|Target stage in Dockerfile to build. If not specified, the Dockerfile is processed entirely to (and including) its last stage.|""|false|
|ENTITLEMENT_SECRET|Name of secret which contains the entitlement certificates|etc-pki-entitlement|false|
|ACTIVATION_KEY|Name of secret which contains subscription activation key|activation-key|false|
|ADDITIONAL_SECRET|Name of a secret which will be made available to the build with 'buildah build --secret' at /run/secrets/$ADDITIONAL_SECRET|does-not-exist|false|
|BUILD_ARGS|Array of --build-arg values ("arg=value" strings)|[]|false|
|BUILD_ARGS_FILE|Path to a file with build arguments, see https://www.mankier.com/1/buildah-build#--build-arg-file|""|false|
|caTrustConfigMapName|The name of the ConfigMap to read CA bundle data from.|trusted-ca|false|
|caTrustConfigMapKey|The name of the key in the ConfigMap that contains the CA bundle data.|ca-bundle.crt|false|
|ICM_KEEP_COMPAT_LOCATION|Whether to keep compatibility location at /root/buildinfo/ for ICM injection|true|false|
|ADD_CAPABILITIES|Comma separated list of extra capabilities to add when running 'buildah build'|""|false|
|SQUASH|Squash all new and previous layers added as a part of this build, as per --squash|false|false|
|STORAGE_DRIVER|Storage driver to configure for buildah|overlay|false|
|SKIP_UNUSED_STAGES|Whether to skip stages in Containerfile that seem unused by subsequent stages|true|false|
|LABELS|Additional key=value labels that should be applied to the image|[]|false|
|ANNOTATIONS|Additional key=value annotations that should be applied to the image|[]|false|
|ANNOTATIONS_FILE|Path to a file with additional key=value annotations that should be applied to the image|""|false|
|PRIVILEGED_NESTED|Whether to enable privileged mode, should be used only with remote VMs|false|false|
|SKIP_SBOM_GENERATION|Skip SBOM-related operations. This will likely cause EC policies to fail if enabled|false|false|
|SBOM_TYPE|Select the SBOM format to generate. Valid values: spdx, cyclonedx. Note: the SBOM from the prefetch task - if there is one - must be in the same format.|spdx|false|
|BUILDAH_FORMAT|The format for the resulting image's mediaType. Valid values are oci (default) or docker.|oci|false|
|ADDITIONAL_BASE_IMAGES|Additional base image references to include to the SBOM. Array of image_reference_with_digest strings|[]|false|
|WORKINGDIR_MOUNT|Mount the current working directory into the build using --volume $PWD:/$WORKINGDIR_MOUNT. Note that the $PWD will be the context directory for the build (see the CONTEXT param).|""|false|
|INHERIT_BASE_IMAGE_LABELS|Determines if the image inherits the base image labels.|true|false|
|HTTP_PROXY|HTTP/HTTPS proxy to use for the buildah pull and build operations. Will not be passed through to the container during the build process.|""|false|
|NO_PROXY|Comma separated list of hosts or domains which should bypass the HTTP/HTTPS proxy.|""|false|
|PROXY_CA_TRUST_CONFIG_MAP_NAME|The name of the ConfigMap to read proxy CA bundle data from.|proxy-ca-bundle|false|
|PROXY_CA_TRUST_CONFIG_MAP_KEY|The name of the key in the ConfigMap that contains the proxy CA bundle data.|ca-bundle.crt|false|
|image-digest|Digest of the image to which the scan results should be associated.||true|
|image-url|URL of the image to which the scan results should be associated.||true|
|COV_LICENSE|Name of secret which contains the Coverity license|cov-license|false|
|PROJECT_NAME||""|false|
|RECORD_EXCLUDED||false|false|
|TARGET_DIRS|Target directories in component's source code. Multiple values should be separated with commas. This only applies to buildless capture, which is only attempted if buildful capture fails to produce and results.|.|false|
|COV_ANALYZE_ARGS|Arguments to be appended to the cov-analyze command|--enable HARDCODED_CREDENTIALS --security --concurrency --spotbugs-max-mem=4096|false|
|IMP_FINDINGS_ONLY|Report only important findings. Default is true. To report all findings, specify "false"|true|false|
|KFP_GIT_URL|Known False Positives (KFP) git URL (optionally taking a revision delimited by \#). Defaults to "SITE_DEFAULT", which means the default value "https://gitlab.cee.redhat.com/osh/known-false-positives.git" for internal Konflux instance and empty string for external Konflux instance. If set to an empty string, the KFP filtering is disabled.|SITE_DEFAULT|false|

## Results
|name|description|
|---|---|
|TEST_OUTPUT|Tekton task test output.|

## Workspaces
|name|description|optional|
|---|---|---|
|source|Workspace containing the source code to build.|false|

## Additional info

> NOTE: For path exclusions defined in the known-false-positives (KFP) repo to be applied to scan results, the component name should match the respective directory in KFP. By default this is sourced from the `"appstudio.openshift.io/component"` label, but the `PROJECT_NAME` parameter can be used to override this.


The sast-coverity-check task uses Coverity tool to perform Static Application Security Testing (SAST).

The documentation for this mode can be found here: <https://documentation.blackduck.com/bundle/coverity-docs/page/commands/topics/coverity_capture.html>

This task will first attempt buildful scannning which instruments the Containerfile, and builds the container. If that attempt fails, it will
then perform buildless capture on the source code.

Other details:

- Only important findings are reported by default.  A parameter ( `IMP_FINDINGS_ONLY`) is provided to override this configuration.
- The csdiff/v1 SARIF fingerprints are provided for all findings
- A parameter ( `KFP_GIT_URL`) is provided to remove false positives providing a known false positives repository. By default, no repository is provided.

> NOTE: This task is executed only if there is a Coverity license set up in the environment. Please check coverity-availability-check task for more information.

## Source repository for image:

// TODO: Add reference to private repo for the container image once the task is migrated to repo

## Additional links:

* <https://sig-product-docs.synopsys.com/bundle/coverity-docs/page/commands/topics/coverity_capture.html>
* <https://sig-product-docs.synopsys.com/bundle/coverity-docs/page/cli/topics/options_reference.html>
