# "fbc-builder pipeline"
This pipeline is ideal for building and verifying [file-based catalogs](https://konflux-ci.dev/docs/end-to-end/building-olm/#building-the-file-based-catalog).

_Uses `buildah` to create a container image. Its build-time tests are limited to verifying the included catalog and do not scan the image.
This pipeline is pushed as a Tekton bundle to [quay.io](https://quay.io/repository/konflux-ci/tekton-catalog/pipeline-fbc-builder?tab=tags)_

## Parameters
|name|description|default value|used in (taskname:taskrefversion:taskparam)|
|---|---|---|---|
|build-args| Array of --build-arg values ("arg=value" strings) for buildah| []| build-images:0.5:BUILD_ARGS|
|build-args-file| Path to a file with build arguments for buildah, see https://www.mankier.com/1/buildah-build#--build-arg-file| | build-images:0.5:BUILD_ARGS_FILE|
|build-image-index| Add built image into an OCI image index| true| build-image-index:0.1:ALWAYS_BUILD_INDEX|
|build-platforms| List of platforms to build the container images on. The available set of values is determined by the configuration of the multi-platform-controller.| ['linux/x86_64']| |
|build-source-image| Build a source image.| false| |
|dockerfile| Path to the Dockerfile inside the context specified by parameter path-context| Dockerfile| build-images:0.5:DOCKERFILE|
|git-url| Source Repository URL| None| clone-repository:0.1:url|
|hermetic| Execute the build with network isolation| true| build-images:0.5:HERMETIC|
|image-expires-after| Image tag expiration time, time values could be something like 1h, 2d, 3w for hours, days, and weeks, respectively.| | clone-repository:0.1:ociArtifactExpiresAfter ; run-opm-command:0.1:ociArtifactExpiresAfter ; prefetch-dependencies:0.2:ociArtifactExpiresAfter ; build-images:0.5:IMAGE_EXPIRES_AFTER ; build-image-index:0.1:IMAGE_EXPIRES_AFTER|
|output-image| Fully Qualified Output Image| None| init:0.2:image-url ; clone-repository:0.1:ociStorage ; run-opm-command:0.1:ociStorage ; prefetch-dependencies:0.2:ociStorage ; build-images:0.5:IMAGE ; build-image-index:0.1:IMAGE|
|path-context| Path to the source code of an application's component from where to build image.| .| build-images:0.5:CONTEXT|
|prefetch-input| Build dependencies to be prefetched| | prefetch-dependencies:0.2:input ; build-images:0.5:PREFETCH_INPUT|
|rebuild| Force rebuild image| false| init:0.2:rebuild|
|revision| Revision of the Source Repository| | clone-repository:0.1:revision|
|skip-checks| Skip checks against built image| false| init:0.2:skip-checks|

## Available params from tasks
### apply-tags:0.2 task parameters
|name|description|default value|already set by|
|---|---|---|---|
|ADDITIONAL_TAGS| Additional tags that will be applied to the image in the registry.| []| |
|CA_TRUST_CONFIG_MAP_KEY| The name of the key in the ConfigMap that contains the CA bundle data.| ca-bundle.crt| |
|CA_TRUST_CONFIG_MAP_NAME| The name of the ConfigMap to read CA bundle data from.| trusted-ca| |
|IMAGE_DIGEST| Image digest of the built image.| None| '$(tasks.build-image-index.results.IMAGE_DIGEST)'|
|IMAGE_URL| Image repository and tag reference of the the built image.| None| '$(tasks.build-image-index.results.IMAGE_URL)'|
### build-image-index:0.1 task parameters
|name|description|default value|already set by|
|---|---|---|---|
|ALWAYS_BUILD_INDEX| Build an image index even if IMAGES is of length 1. Default true. If the image index generation is skipped, the task will forward values for params.IMAGES[0] to results.IMAGE_*. In order to properly set all results, use the repository:tag@sha256:digest format for the IMAGES parameter.| true| '$(params.build-image-index)'|
|BUILDAH_FORMAT| The format for the resulting image's mediaType. Valid values are oci (default) or docker.| oci| |
|COMMIT_SHA| The commit the image is built from.| | '$(tasks.clone-repository.results.commit)'|
|IMAGE| The target image and tag where the image will be pushed to.| None| '$(params.output-image)'|
|IMAGES| List of Image Manifests to be referenced by the Image Index| None| '['$(tasks.build-images.results.IMAGE_REF[*])']'|
|IMAGE_EXPIRES_AFTER| Delete image tag after specified time resulting in garbage collection of the digest. Empty means to keep the image tag. Time values could be something like 1h, 2d, 3w for hours, days, and weeks, respectively.| | '$(params.image-expires-after)'|
|STORAGE_DRIVER| Storage driver to configure for buildah| vfs| |
|TLSVERIFY| Verify the TLS on the registry endpoint (for push/pull to a non-TLS registry)| true| |
### buildah-remote-oci-ta:0.5 task parameters
|name|description|default value|already set by|
|---|---|---|---|
|ACTIVATION_KEY| Name of secret which contains subscription activation key| activation-key| |
|ADDITIONAL_BASE_IMAGES| Additional base image references to include to the SBOM. Array of image_reference_with_digest strings| []| |
|ADDITIONAL_SECRET| Name of a secret which will be made available to the build with 'buildah build --secret' at /run/secrets/$ADDITIONAL_SECRET| does-not-exist| |
|ADD_CAPABILITIES| Comma separated list of extra capabilities to add when running 'buildah build'| | |
|ANNOTATIONS| Additional key=value annotations that should be applied to the image| []| |
|ANNOTATIONS_FILE| Path to a file with additional key=value annotations that should be applied to the image| | |
|BUILDAH_FORMAT| The format for the resulting image's mediaType. Valid values are oci (default) or docker.| oci| |
|BUILD_ARGS| Array of --build-arg values ("arg=value" strings)| []| '['$(params.build-args[*])']'|
|BUILD_ARGS_FILE| Path to a file with build arguments, see https://www.mankier.com/1/buildah-build#--build-arg-file| | '$(params.build-args-file)'|
|BUILD_TIMESTAMP| Defines the single build time for all buildah builds in seconds since UNIX epoch| | |
|CACHI2_ARTIFACT| The Trusted Artifact URI pointing to the artifact with the prefetched dependencies.| | '$(tasks.prefetch-dependencies.results.CACHI2_ARTIFACT)'|
|COMMIT_SHA| The image is built from this commit.| | '$(tasks.clone-repository.results.commit)'|
|CONTEXT| Path to the directory to use as context.| .| '$(params.path-context)'|
|DOCKERFILE| Path to the Dockerfile to build.| ./Dockerfile| '$(params.dockerfile)'|
|ENTITLEMENT_SECRET| Name of secret which contains the entitlement certificates| etc-pki-entitlement| |
|HERMETIC| Determines if build will be executed without network access.| false| '$(params.hermetic)'|
|HTTP_PROXY| HTTP/HTTPS proxy to use for the buildah pull and build operations. Will not be passed through to the container during the build process.| | |
|ICM_KEEP_COMPAT_LOCATION| Whether to keep compatibility location at /root/buildinfo/ for ICM injection| true| |
|IMAGE| Reference of the image buildah will produce.| None| '$(params.output-image)'|
|IMAGE_APPEND_PLATFORM| Whether to append a sanitized platform architecture on the IMAGE tag| false| 'true'|
|IMAGE_EXPIRES_AFTER| Delete image tag after specified time. Empty means to keep the image tag. Time values could be something like 1h, 2d, 3w for hours, days, and weeks, respectively.| | '$(params.image-expires-after)'|
|INHERIT_BASE_IMAGE_LABELS| Determines if the image inherits the base image labels.| true| |
|LABELS| Additional key=value labels that should be applied to the image| []| |
|NO_PROXY| Comma separated list of hosts or domains which should bypass the HTTP/HTTPS proxy.| | |
|PLATFORM| The platform to build on| None| |
|PREFETCH_INPUT| In case it is not empty, the prefetched content should be made available to the build.| | '$(params.prefetch-input)'|
|PRIVILEGED_NESTED| Whether to enable privileged mode, should be used only with remote VMs| false| |
|PROXY_CA_TRUST_CONFIG_MAP_KEY| The name of the key in the ConfigMap that contains the proxy CA bundle data.| ca-bundle.crt| |
|PROXY_CA_TRUST_CONFIG_MAP_NAME| The name of the ConfigMap to read proxy CA bundle data from.| proxy-ca-bundle| |
|SBOM_TYPE| Select the SBOM format to generate. Valid values: spdx, cyclonedx. Note: the SBOM from the prefetch task - if there is one - must be in the same format.| spdx| |
|SKIP_SBOM_GENERATION| Skip SBOM-related operations. This will likely cause EC policies to fail if enabled| false| |
|SKIP_UNUSED_STAGES| Whether to skip stages in Containerfile that seem unused by subsequent stages| true| |
|SOURCE_ARTIFACT| The Trusted Artifact URI pointing to the artifact with the application source code.| None| '$(tasks.prefetch-dependencies.results.SOURCE_ARTIFACT)'|
|SOURCE_URL| The image is built from this URL.| | '$(tasks.clone-repository.results.url)'|
|SQUASH| Squash all new and previous layers added as a part of this build, as per --squash| false| |
|STORAGE_DRIVER| Storage driver to configure for buildah| overlay| |
|TARGET_STAGE| Target stage in Dockerfile to build. If not specified, the Dockerfile is processed entirely to (and including) its last stage.| | |
|TLSVERIFY| Verify the TLS on the registry endpoint (for push/pull to a non-TLS registry)| true| |
|WORKINGDIR_MOUNT| Mount the current working directory into the build using --volume $PWD:/$WORKINGDIR_MOUNT. Note that the $PWD will be the context directory for the build (see the CONTEXT param).| | |
|YUM_REPOS_D_FETCHED| Path in source workspace where dynamically-fetched repos are present| fetched.repos.d| |
|YUM_REPOS_D_SRC| Path in the git repository in which yum repository files are stored| repos.d| |
|YUM_REPOS_D_TARGET| Target path on the container in which yum repository files should be made available| /etc/yum.repos.d| |
|caTrustConfigMapKey| The name of the key in the ConfigMap that contains the CA bundle data.| ca-bundle.crt| |
|caTrustConfigMapName| The name of the ConfigMap to read CA bundle data from.| trusted-ca| |
### deprecated-image-check:0.5 task parameters
|name|description|default value|already set by|
|---|---|---|---|
|BASE_IMAGES_DIGESTS| Digests of base build images.| | |
|CA_TRUST_CONFIG_MAP_KEY| The name of the key in the ConfigMap that contains the CA bundle data.| ca-bundle.crt| |
|CA_TRUST_CONFIG_MAP_NAME| The name of the ConfigMap to read CA bundle data from.| trusted-ca| |
|IMAGE_DIGEST| Image digest.| None| '$(tasks.build-image-index.results.IMAGE_DIGEST)'|
|IMAGE_URL| Fully qualified image name.| None| '$(tasks.build-image-index.results.IMAGE_URL)'|
|POLICY_DIR| Path to directory containing Conftest policies.| /project/repository/| |
|POLICY_NAMESPACE| Namespace for Conftest policy.| required_checks| |
### fbc-fips-check-oci-ta:0.1 task parameters
|name|description|default value|already set by|
|---|---|---|---|
|SOURCE_ARTIFACT| The Trusted Artifact URI pointing to the artifact with the application source code.| None| '$(tasks.prefetch-dependencies.results.SOURCE_ARTIFACT)'|
|image-digest| Image digest to scan.| None| '$(tasks.build-image-index.results.IMAGE_DIGEST)'|
|image-url| Image URL.| None| '$(tasks.build-image-index.results.IMAGE_URL)'|
### fbc-target-index-pruning-check:0.1 task parameters
|name|description|default value|already set by|
|---|---|---|---|
|IMAGE_DIGEST| Image digest.| None| '$(tasks.build-image-index.results.IMAGE_DIGEST)'|
|IMAGE_URL| Fully qualified image name.| None| '$(tasks.build-image-index.results.IMAGE_URL)'|
|RENDERED_CATALOG_DIGEST| Digest for attached json file containing the FBC fragment's opm rendered catalog.| None| '$(tasks.validate-fbc.results.RENDERED_CATALOG_DIGEST)'|
|TARGET_INDEX| Image name of target index, minus tag.| registry.redhat.io/redhat/redhat-operator-index| 'registry.redhat.io/redhat/redhat-operator-index'|
### git-clone-oci-ta:0.1 task parameters
|name|description|default value|already set by|
|---|---|---|---|
|caTrustConfigMapKey| The name of the key in the ConfigMap that contains the CA bundle data.| ca-bundle.crt| |
|caTrustConfigMapName| The name of the ConfigMap to read CA bundle data from.| trusted-ca| |
|depth| Perform a shallow clone, fetching only the most recent N commits.| 1| |
|enableSymlinkCheck| Check symlinks in the repo. If they're pointing outside of the repo, the build will fail. | true| |
|fetchSubmoduleTags| Fetch all tags from all submodules.| false| |
|fetchTags| Fetch all tags for the repo.| false| |
|httpProxy| HTTP proxy server for non-SSL requests.| | |
|httpsProxy| HTTPS proxy server for SSL requests.| | |
|mergeTargetBranch| Set to "true" to merge the targetBranch into the checked-out revision.| false| |
|noProxy| Opt out of proxying HTTP/HTTPS requests.| | |
|ociArtifactExpiresAfter| Expiration date for the trusted artifacts created in the OCI repository. An empty string means the artifacts do not expire.| | '$(params.image-expires-after)'|
|ociStorage| The OCI repository where the Trusted Artifacts are stored.| None| '$(params.output-image).git'|
|refspec| Refspec to fetch before checking out revision.| | |
|revision| Revision to checkout. (branch, tag, sha, ref, etc...)| | '$(params.revision)'|
|shortCommitLength| Length of short commit SHA| 7| |
|sparseCheckoutDirectories| Define the directory patterns to match or exclude when performing a sparse checkout.| | |
|sslVerify| Set the `http.sslVerify` global git config. Setting this to `false` is not advised unless you are sure that you trust your git remote.| true| |
|submodules| Initialize and fetch git submodules.| true| |
|targetBranch| The target branch to merge into the revision (if mergeTargetBranch is true).| main| |
|url| Repository URL to clone from.| None| '$(params.git-url)'|
|userHome| Absolute path to the user's home directory. Set this explicitly if you are running the image as a non-root user. | /tekton/home| |
|verbose| Log the commands that are executed during `git-clone`'s operation.| false| |
### init:0.2 task parameters
|name|description|default value|already set by|
|---|---|---|---|
|image-url| Image URL for build by PipelineRun| None| '$(params.output-image)'|
|rebuild| Rebuild the image if exists| false| '$(params.rebuild)'|
|skip-checks| Skip checks against built image| false| '$(params.skip-checks)'|
### prefetch-dependencies-oci-ta:0.2 task parameters
|name|description|default value|already set by|
|---|---|---|---|
|ACTIVATION_KEY| Name of secret which contains subscription activation key| activation-key| |
|SOURCE_ARTIFACT| The Trusted Artifact URI pointing to the artifact with the application source code.| None| '$(tasks.run-opm-command.results.SOURCE_ARTIFACT)'|
|caTrustConfigMapKey| The name of the key in the ConfigMap that contains the CA bundle data.| ca-bundle.crt| |
|caTrustConfigMapName| The name of the ConfigMap to read CA bundle data from.| trusted-ca| |
|config-file-content| Pass configuration to the prefetch tool. Note this needs to be passed as a YAML-formatted config dump, not as a file path! | | |
|dev-package-managers| Enable in-development package managers. WARNING: the behavior may change at any time without notice. Use at your own risk. | false| |
|input| Configures project packages that will have their dependencies prefetched.| None| '$(params.prefetch-input)'|
|log-level| Set prefetch tool log level (debug, info, warning, error)| info| |
|ociArtifactExpiresAfter| Expiration date for the trusted artifacts created in the OCI repository. An empty string means the artifacts do not expire.| | '$(params.image-expires-after)'|
|ociStorage| The OCI repository where the Trusted Artifacts are stored.| None| '$(params.output-image).prefetch'|
|sbom-type| Select the SBOM format to generate. Valid values: spdx, cyclonedx.| spdx| |
### run-opm-command-oci-ta:0.1 task parameters
|name|description|default value|already set by|
|---|---|---|---|
|FILE_TO_UPDATE_PULLSPEC| Optional. Relative path to a file (e.g., catalog-template.yml) in which pullspecs should be updated before running opm.| | |
|IDMS_PATH| Optional, path for ImageDigestMirrorSet file. It defaults to '.tekton/images-mirror-set.yaml'| .tekton/images-mirror-set.yaml| |
|OPM_ARGS| The array of arguments to pass to the 'opm' command. (e.g., [ 'alpha', 'render-template', 'basic', 'v4.18/catalog-template.json']).| []| []|
|OPM_OUTPUT_PATH| Relative path for the opm command's output file (e.g. 'v4.18/catalog/example-operator/catalog.json'). Relative to the root directory of given source code (Git repository).| None| |
|SOURCE_ARTIFACT| The Trusted Artifact URI pointing to the artifact with the application source code.| None| '$(tasks.clone-repository.results.SOURCE_ARTIFACT)'|
|ociArtifactExpiresAfter| Expiration date for the trusted artifacts. Empty string means no expiration.| None| '$(params.image-expires-after)'|
|ociStorage| The OCI repository where the Trusted Artifacts are stored.| None| '$(params.output-image).opm'|
### validate-fbc:0.1 task parameters
|name|description|default value|already set by|
|---|---|---|---|
|IMAGE_DIGEST| Image digest.| None| '$(tasks.build-image-index.results.IMAGE_DIGEST)'|
|IMAGE_URL| Fully qualified image name.| None| '$(tasks.build-image-index.results.IMAGE_URL)'|

## Results
|name|description|value|
|---|---|---|
|CHAINS-GIT_COMMIT| |$(tasks.clone-repository.results.commit)|
|CHAINS-GIT_URL| |$(tasks.clone-repository.results.url)|
|IMAGE_DIGEST| |$(tasks.build-image-index.results.IMAGE_DIGEST)|
|IMAGE_URL| |$(tasks.build-image-index.results.IMAGE_URL)|
## Available results from tasks
### build-image-index:0.1 task results
|name|description|used in params (taskname:taskrefversion:taskparam)
|---|---|---|
|IMAGES| List of all referenced image manifests| |
|IMAGE_DIGEST| Digest of the image just built| deprecated-base-image-check:0.5:IMAGE_DIGEST ; apply-tags:0.2:IMAGE_DIGEST ; validate-fbc:0.1:IMAGE_DIGEST ; fbc-target-index-pruning-check:0.1:IMAGE_DIGEST ; fbc-fips-check-oci-ta:0.1:image-digest|
|IMAGE_REF| Image reference of the built image containing both the repository and the digest| |
|IMAGE_URL| Image repository and tag where the built image was pushed| deprecated-base-image-check:0.5:IMAGE_URL ; apply-tags:0.2:IMAGE_URL ; validate-fbc:0.1:IMAGE_URL ; fbc-target-index-pruning-check:0.1:IMAGE_URL ; fbc-fips-check-oci-ta:0.1:image-url|
|SBOM_BLOB_URL| Reference of SBOM blob digest to enable digest-based verification from provenance| |
### buildah-remote-oci-ta:0.5 task results
|name|description|used in params (taskname:taskrefversion:taskparam)
|---|---|---|
|IMAGE_DIGEST| Digest of the image just built| |
|IMAGE_REF| Image reference of the built image| build-image-index:0.1:IMAGES|
|IMAGE_URL| Image repository and tag where the built image was pushed| |
|SBOM_BLOB_URL| Reference of SBOM blob digest to enable digest-based verification from provenance| |
### deprecated-image-check:0.5 task results
|name|description|used in params (taskname:taskrefversion:taskparam)
|---|---|---|
|IMAGES_PROCESSED| Images processed in the task.| |
|TEST_OUTPUT| Tekton task test output.| |
### fbc-fips-check-oci-ta:0.1 task results
|name|description|used in params (taskname:taskrefversion:taskparam)
|---|---|---|
|IMAGES_PROCESSED| Images processed in the task.| |
|TEST_OUTPUT| Tekton task test output.| |
### fbc-target-index-pruning-check:0.1 task results
|name|description|used in params (taskname:taskrefversion:taskparam)
|---|---|---|
|IMAGES_PROCESSED| Images processed in the task.| |
|TEST_OUTPUT| Tekton task test output.| |
### git-clone-oci-ta:0.1 task results
|name|description|used in params (taskname:taskrefversion:taskparam)
|---|---|---|
|CHAINS-GIT_COMMIT| The precise commit SHA that was fetched by this Task. This result uses Chains type hinting to include in the provenance.| |
|CHAINS-GIT_URL| The precise URL that was fetched by this Task. This result uses Chains type hinting to include in the provenance.| |
|SOURCE_ARTIFACT| The Trusted Artifact URI pointing to the artifact with the application source code.| run-opm-command:0.1:SOURCE_ARTIFACT|
|commit| The precise commit SHA that was fetched by this Task.| build-images:0.5:COMMIT_SHA ; build-image-index:0.1:COMMIT_SHA|
|commit-timestamp| The commit timestamp of the checkout| |
|merged_sha| The SHA of the commit after merging the target branch (if the param mergeTargetBranch is true).| |
|short-commit| The commit SHA that was fetched by this Task limited to params.shortCommitLength number of characters| |
|url| The precise URL that was fetched by this Task.| build-images:0.5:SOURCE_URL|
### init:0.2 task results
|name|description|used in params (taskname:taskrefversion:taskparam)
|---|---|---|
|build| Defines if the image in param image-url should be built| |
### prefetch-dependencies-oci-ta:0.2 task results
|name|description|used in params (taskname:taskrefversion:taskparam)
|---|---|---|
|CACHI2_ARTIFACT| The Trusted Artifact URI pointing to the artifact with the prefetched dependencies.| build-images:0.5:CACHI2_ARTIFACT|
|SOURCE_ARTIFACT| The Trusted Artifact URI pointing to the artifact with the application source code.| build-images:0.5:SOURCE_ARTIFACT ; fbc-fips-check-oci-ta:0.1:SOURCE_ARTIFACT|
### run-opm-command-oci-ta:0.1 task results
|name|description|used in params (taskname:taskrefversion:taskparam)
|---|---|---|
|SOURCE_ARTIFACT| The Trusted Artifact URI pointing to the artifact with the application source code with generated file-based catalog from catalog-template.yml.| prefetch-dependencies:0.2:SOURCE_ARTIFACT|
### validate-fbc:0.1 task results
|name|description|used in params (taskname:taskrefversion:taskparam)
|---|---|---|
|IMAGES_PROCESSED| Images processed in the task.| |
|RELATED_IMAGES_DIGEST| Digest for attached json file containing related images| |
|RELATED_IMAGE_ARTIFACT| The Trusted Artifact URI pointing to the artifact with the related images for the FBC fragment.| |
|RENDERED_CATALOG_DIGEST| Digest for attached json file containing the FBC fragment's opm rendered catalog.| fbc-target-index-pruning-check:0.1:RENDERED_CATALOG_DIGEST|
|TEST_OUTPUT| Tekton task test output.| |
|TEST_OUTPUT_ARTIFACT| The Trusted Artifact URI pointing to the artifact with the related images for the FBC fragment.| |

## Workspaces
|name|description|optional|used in tasks
|---|---|---|---|
|git-auth| |True| clone-repository:0.1:basic-auth ; prefetch-dependencies:0.2:git-basic-auth|
|netrc| |True| prefetch-dependencies:0.2:netrc|
## Available workspaces from tasks
### git-clone-oci-ta:0.1 task workspaces
|name|description|optional|workspace from pipeline
|---|---|---|---|
|basic-auth| A Workspace containing a .gitconfig and .git-credentials file or username and password. These will be copied to the user's home before any git commands are run. Any other files in this Workspace are ignored. It is strongly recommended to use ssh-directory over basic-auth whenever possible and to bind a Secret to this Workspace over other volume types. | True| git-auth|
|ssh-directory| A .ssh directory with private key, known_hosts, config, etc. Copied to the user's home before git commands are executed. Used to authenticate with the git remote when performing the clone. Binding a Secret to this Workspace is strongly recommended over other volume types. | True| |
### prefetch-dependencies-oci-ta:0.2 task workspaces
|name|description|optional|workspace from pipeline
|---|---|---|---|
|git-basic-auth| A Workspace containing a .gitconfig and .git-credentials file or username and password. These will be copied to the user's home before prefetch is run. Any other files in this Workspace are ignored. It is strongly recommended to bind a Secret to this Workspace over other volume types. | True| git-auth|
|netrc| Workspace containing a .netrc file. Prefetch will use the credentials in this file when performing http(s) requests. | True| netrc|
