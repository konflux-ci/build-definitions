# "verify-reproducibility pipeline"
Rebuilds an image from the source it claims to have been built from,
using the same reproducibility params, and checks whether the two
digests match. Run it on demand against an image you want to verify -
it isn't part of the automatic build flow. The rebuild pushes to a
separate, caller-supplied scratch repository, never to the repo of the
image being verified, so running this never changes that image.

Single-arch images only, for now: this pipeline rebuilds through one
buildah-oci-ta run, so its digest can never match a multi-platform
image index digest (from docker-build-multi-platform-oci-ta /
build-image-index). Multi-arch manifest ordering is still open work
(see ADR-0069).

A matching digest proves the same source, params, and task version
produce the same bytes on this platform - it does not prove an
independent platform would agree. If the platform running this
pipeline is the same one that built the original image, and that
platform were tampered with in a way that doesn't break its own
determinism, both builds would agree with each other while still
being wrong. Catching that needs an independent platform rebuilding
from the provenance recipe, which ADR-0069 calls out as a stronger
property this pipeline's shape could grow into, but isn't what it
does today.

This can only be as faithful as the params it's given: if the original
build used a non-default value for something this pipeline exposes
(source-date-epoch, image-expires-after, hermetic, ...), pass the same
value here, or you'll get a false "not reproducible" result that has
nothing to do with real non-determinism.

## Parameters
|name|description|default value|used in (taskname:taskrefversion:taskparam)|
|---|---|---|---|
|build-args| --build-arg values the original build used. Must match the original build.| []| rebuild:0.10:BUILD_ARGS|
|build-args-file| Path to a build-args file, if the original build used one. Must match the original build.| | rebuild:0.10:BUILD_ARGS_FILE|
|buildah-format| Image mediaType the original build used (oci or docker). Must match the original build.| docker| rebuild:0.10:BUILDAH_FORMAT|
|cachi2-artifact| Trusted Artifact URI for prefetched hermetic dependencies (CACHI2_ARTIFACT result). Set alongside hermetic=true for a faithful hermetic rebuild.| | rebuild:0.10:CACHI2_ARTIFACT|
|dockerfile| Path to the Dockerfile inside path-context. Must match the original build.| Dockerfile| rebuild:0.10:DOCKERFILE|
|git-url| Source repository URL the original image was built from. Must match the original build's git URL exactly - it's baked into a digest-affecting label, so a mismatch here alone causes a false "not reproducible" result. | None| rebuild:0.10:SOURCE_URL|
|hermetic| Whether the original build ran with network access disabled. Must match the original build.| false| rebuild:0.10:HERMETIC|
|image-digest| Digest (sha256:...) of the image being verified.| None| |
|image-expires-after| The image-expires-after value the original build used (leave empty if it didn't set one). Echoed straight through to the rebuild - buildah bakes this into a quay.expires-after label in the image config, so a mismatch here alone causes a false "not reproducible" result. This is not a cleanup knob for the verify-* tag this pipeline pushes - use a registry-side auto-prune policy scoped to that tag pattern for that instead. | | rebuild:0.10:IMAGE_EXPIRES_AFTER|
|image-repository| Repository (no tag or digest) of the image being verified.| None| validate-params:0.1:REPOSITORY_A ; compare:0.1:ORIGINAL_IMAGE_REF|
|omit-history| The omit-history value the original build used. Must match the original build.| false| rebuild:0.10:OMIT_HISTORY|
|path-context| Path to the source code to build. Must match the original build.| .| rebuild:0.10:CONTEXT|
|prefetch-input| Prefetch config the original build used, if hermetic. Must match the original build.| | rebuild:0.10:PREFETCH_INPUT|
|privileged-nested| Whether the original build ran in privileged mode. Must match the original build.| false| rebuild:0.10:PRIVILEGED_NESTED|
|revision| Resolved commit SHA (not a branch name) the original image was built from. Must match the original build exactly, same reason as git-url above. | None| rebuild:0.10:COMMIT_SHA|
|rewrite-timestamp| The rewrite-timestamp value the original build used. Must match the original build.| false| rebuild:0.10:REWRITE_TIMESTAMP|
|skip-sbom-generation| Skips SBOM generation, SBOM upload, and SBOM attestation signing on the rebuild. Doesn't affect the digest comparison - the rebuild's IMAGE_DIGEST is set before any SBOM step runs. Defaults on since the rebuild's SBOM has nowhere useful to go. Set to "false" if you're using this pipeline to check whether syft produces byte-identical SBOMs across rebuilds (ADR-0069's open question on that). | true| rebuild:0.10:SKIP_SBOM_GENERATION|
|source-artifact| Trusted Artifact URI for the exact source the original image was built from (the SOURCE_ARTIFACT result from that build's clone-repository or prefetch-dependencies task). This expires on the same schedule as the original build's image-expires-after, so verification generally needs to run before that window closes. | None| rebuild:0.10:SOURCE_ARTIFACT|
|source-date-epoch| The source-date-epoch value the original build used. Must match the original build.| | rebuild:0.10:SOURCE_DATE_EPOCH|
|verify-repository| Scratch repository the rebuild pushes to, tagged verify-<pipelineRun-uid>. Must be a different repository than image-repository: buildah-oci-ta signs every push whenever the cluster has keyless signing configured, and cosign's signature tag is repo-scoped, so pushing the rebuild into the same repo as the image being verified would overwrite that image's own signature (and SBOM/attestation tags) just by inspecting it. | None| validate-params:0.1:REPOSITORY_B ; rebuild:0.10:IMAGE|

## Available params from tasks
### buildah-oci-ta:0.10 task parameters
|name|description|default value|already set by|
|---|---|---|---|
|ACTIVATION_KEY| Name of secret which contains subscription activation key| activation-key| |
|ADDITIONAL_BASE_IMAGES| Additional base image references to include to the SBOM. Array of image_reference_with_digest strings| []| |
|ADDITIONAL_SECRET| Name of a secret which will be made available to the build with 'buildah build --secret' at /run/secrets/$ADDITIONAL_SECRET| does-not-exist| |
|ADD_CAPABILITIES| Comma separated list of extra capabilities to add when running 'buildah build'| ""| |
|ALLOW_CROSS_PLATFORM_IMAGES| Allows to use parent images that don't match the build host architecture. This option must be used with caution as it may create incompatible images.| false| |
|ANNOTATIONS| Additional key=value annotations that should be applied to the image| []| |
|ANNOTATIONS_FILE| Path to a file with additional key=value annotations that should be applied to the image| ""| |
|BUILDAH_FORMAT| The format for the resulting image's mediaType. Valid values are oci (default) or docker.| oci| '$(params.buildah-format)'|
|BUILD_ARGS| Array of --build-arg values ("arg=value" strings)| []| '['$(params.build-args[*])']'|
|BUILD_ARGS_FILE| Path to a file with build arguments, see https://www.mankier.com/1/buildah-build#--build-arg-file| ""| '$(params.build-args-file)'|
|BUILD_TIMESTAMP| Defines the single build time for all buildah builds in seconds since UNIX epoch. Conflicts with SOURCE_DATE_EPOCH.| ""| |
|CACHI2_ARTIFACT| The Trusted Artifact URI pointing to the artifact with the prefetched dependencies.| ""| '$(params.cachi2-artifact)'|
|COMMIT_SHA| The image is built from this commit.| ""| '$(params.revision)'|
|CONTEXT| Path to the directory to use as context.| .| '$(params.path-context)'|
|CONTEXTUALIZE_SBOM| Determines if SBOM will be contextualized.| true| |
|DOCKERFILE| Path to the Dockerfile to build.| ./Dockerfile| '$(params.dockerfile)'|
|ENTITLEMENT_SECRET| Name of secret which contains the entitlement certificates| etc-pki-entitlement| |
|ENV_VARS| Array of --env values ("env=value" strings)| []| |
|HERMETIC| Determines if build will be executed without network access.| false| '$(params.hermetic)'|
|HTTP_PROXY| HTTP/HTTPS proxy to use for the buildah pull and build operations. Will not be passed through to the container during the build process.| ""| |
|ICM_KEEP_COMPAT_LOCATION| Whether to keep compatibility location at /root/buildinfo/ for ICM injection| true| |
|IMAGE| Reference of the image buildah will produce.| None| '$(params.verify-repository):verify-$(context.pipelineRun.uid)'|
|IMAGE_EXPIRES_AFTER| Delete image tag after specified time. Empty means to keep the image tag. Time values could be something like 1h, 2d, 3w for hours, days, and weeks, respectively.| ""| '$(params.image-expires-after)'|
|INHERIT_BASE_IMAGE_LABELS| Determines if the image inherits the base image labels.| true| |
|LABELS| Additional key=value labels that should be applied to the image| []| |
|LOG_LEVEL| Log level for the build command.| info| |
|NO_PROXY| Comma separated list of hosts or domains which should bypass the HTTP/HTTPS proxy.| ""| |
|OMIT_HISTORY| Omit build history information from the resulting image. Improves reproducibility by excluding timestamps and layer metadata.| false| '$(params.omit-history)'|
|PREFETCH_INPUT| In case it is not empty, the prefetched content should be made available to the build.| ""| '$(params.prefetch-input)'|
|PRIVILEGED_NESTED| Whether to enable privileged mode, should be used only with remote VMs| false| '$(params.privileged-nested)'|
|PROXY_CA_TRUST_CONFIG_MAP_KEY| The name of the key in the ConfigMap that contains the proxy CA bundle data.| ca-bundle.crt| |
|PROXY_CA_TRUST_CONFIG_MAP_NAME| The name of the ConfigMap to read proxy CA bundle data from.| caching-ca-bundle| |
|REWRITE_TIMESTAMP| Clamp mtime of all files to at most SOURCE_DATE_EPOCH. Does nothing if SOURCE_DATE_EPOCH is not defined.| false| '$(params.rewrite-timestamp)'|
|RHSM_MOUNT_CA_CERTS| Mount /etc/rhsm/ca from the host machine into the build. Valid values are 'always', 'auto' (default), 'never'. Only effective if HERMETIC=false and ACTIVATION_KEY or ENTITLEMENT_SECRET is set.| auto| |
|SBOM_SKIP_VALIDATION| Flag to enable or disable SBOM validation before save. Validation is optional - use this if you are experiencing performance issues.| true| |
|SBOM_SOURCE_SCAN_ENABLED| Flag to enable or disable SBOM generation from source code. The scanner of the source code is enabled only for non-hermetic builds and can be disabled if the SBOM_SYFT_SELECT_CATALOGERS can't turn off catalogers that cause false positives on source code scanning.| true| |
|SBOM_SYFT_SELECT_CATALOGERS| Extra option to customize Syft's default catalogers when generating SBOMs. The value corresponds to Syft's CLI flag --select-catalogers. The details about available catalogers can be found here: https://github.com/anchore/syft/wiki/Package-Cataloger-Selection| ""| |
|SBOM_TYPE| Select the SBOM format to generate. Valid values: spdx, cyclonedx. Note: the SBOM from the prefetch task - if there is one - must be in the same format.| spdx| |
|SKIP_INJECTIONS| Don't inject a content-sets.json or a labels.json file. This requires that the canonical Containerfile takes care of this itself.| false| |
|SKIP_SBOM_GENERATION| Skip SBOM-related operations. This will likely cause EC policies to fail if enabled| false| '$(params.skip-sbom-generation)'|
|SKIP_UNUSED_STAGES| Whether to skip stages in Containerfile that seem unused by subsequent stages| true| |
|SOURCE_ARTIFACT| The Trusted Artifact URI pointing to the artifact with the application source code.| None| '$(params.source-artifact)'|
|SOURCE_DATE_EPOCH| Timestamp in seconds since Unix epoch for reproducible builds. Sets image created time and SOURCE_DATE_EPOCH build arg. Conflicts with BUILD_TIMESTAMP.| ""| '$(params.source-date-epoch)'|
|SOURCE_URL| The image is built from this URL.| ""| '$(params.git-url)'|
|SQUASH| Squash all new and previous layers added as a part of this build, as per --squash| false| |
|STORAGE_DRIVER| Storage driver to configure for buildah| overlay| |
|TARGET_STAGE| Target stage in Dockerfile to build. If not specified, the Dockerfile is processed entirely to (and including) its last stage.| ""| |
|TLSVERIFY| Verify the TLS on the registry endpoint (for push/pull to a non-TLS registry)| true| |
|WORKINGDIR_MOUNT| Mount the current working directory into the build using --volume $PWD:/$WORKINGDIR_MOUNT. Note that the $PWD will be the context directory for the build (see the CONTEXT param).| ""| |
|YUM_REPOS_D_FETCHED| Path in source workspace where dynamically-fetched repos are present| fetched.repos.d| |
|YUM_REPOS_D_SRC| Path in the git repository in which yum repository files are stored| repos.d| |
|YUM_REPOS_D_TARGET| Target path on the container in which yum repository files should be made available| /etc/yum.repos.d| |
|caTrustConfigMapKey| The name of the key in the ConfigMap that contains the CA bundle data.| ca-bundle.crt| |
|caTrustConfigMapName| The name of the ConfigMap to read CA bundle data from.| trusted-ca| |
### verify-distinct-repositories:0.1 task parameters
|name|description|default value|already set by|
|---|---|---|---|
|REPOSITORY_A| First repository to compare.| None| '$(params.image-repository)'|
|REPOSITORY_B| Second repository to compare.| None| '$(params.verify-repository)'|
### verify-reproducibility:0.1 task parameters
|name|description|default value|already set by|
|---|---|---|---|
|ORIGINAL_IMAGE_REF| Reference (repo@sha256:...) of the original image being verified.| None| '$(params.image-repository)@$(params.image-digest)'|
|REBUILT_IMAGE_REF| Reference (repo@sha256:...) of the freshly rebuilt image to compare against.| None| '$(tasks.rebuild.results.IMAGE_REF)'|

## Results
|name|description|value|
|---|---|---|
|REBUILT_IMAGE_REF| |$(tasks.rebuild.results.IMAGE_REF)|
|REPRODUCIBLE| |$(tasks.compare.results.REPRODUCIBLE)|
|TEST_OUTPUT| |$(tasks.compare.results.TEST_OUTPUT)|
## Available results from tasks
### buildah-oci-ta:0.10 task results
|name|description|used in params (taskname:taskrefversion:taskparam)
|---|---|---|
|IMAGE_DIGEST| Digest of the image just built| |
|IMAGE_REF| Image reference of the built image| compare:0.1:REBUILT_IMAGE_REF|
|IMAGE_URL| Image repository and tag where the built image was pushed| |
|SBOM_BLOB_URL| Reference of SBOM blob digest to enable digest-based verification from provenance| |
### verify-reproducibility:0.1 task results
|name|description|used in params (taskname:taskrefversion:taskparam)
|---|---|---|
|REPRODUCIBLE| true if the rebuilt image's digest matches the original image's digest, false otherwise| |
|TEST_OUTPUT| JSON formatted test results for the reproducibility comparison| |

## Workspaces
|name|description|optional|used in tasks
|---|---|---|---|
## Available workspaces from tasks
