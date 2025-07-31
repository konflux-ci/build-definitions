#!/bin/bash
set -euo pipefail
echo "[$(date --utc -Ins)] Update CA trust"
ca_bundle=/mnt/trusted-ca/ca-bundle.crt
if [ -f "$ca_bundle" ]; then
  echo "INFO: Using mounted CA bundle: $ca_bundle"
  cp -vf "$ca_bundle" /etc/pki/ca-trust/source/anchors
  update-ca-trust
fi
# Check if we're reusing an existing artifact (from pre-build step)
REUSED_IMAGE_REF=$(cat "$(results.REUSED_IMAGE_REF.path)" 2>/dev/null || echo "")

if [ -n "$REUSED_IMAGE_REF" ]; then
  echo "[$(date --utc -Ins)] Reusing existing artifact - skipping build"
  # Re-emit the REUSED_IMAGE_REF result for downstream steps
  echo -n "$REUSED_IMAGE_REF" | tee "$(results.REUSED_IMAGE_REF.path)"
  echo "[$(date --utc -Ins)] End build"
  exit 0
fi

# If we get here, we need to build a new image
echo "[$(date --utc -Ins)] Building new image"

echo "[$(date --utc -Ins)] Prepare Dockerfile"
if [ -e "$SOURCE_CODE_DIR/$CONTEXT/$DOCKERFILE" ]; then
dockerfile_path="$(pwd)/$SOURCE_CODE_DIR/$CONTEXT/$DOCKERFILE"
elif [ -e "$SOURCE_CODE_DIR/$DOCKERFILE" ]; then
dockerfile_path="$(pwd)/$SOURCE_CODE_DIR/$DOCKERFILE"
elif [ -e "$DOCKERFILE" ]; then
# Instrumented builds (SAST) use this custom dockerfile step as their base
dockerfile_path="$DOCKERFILE"
elif echo "$DOCKERFILE" | grep -q "^https?://"; then
echo "Fetch Dockerfile from $DOCKERFILE"
dockerfile_path=$(mktemp --suffix=-Dockerfile)
http_code=$(curl -s -S -L -w "%{\http_code}" --output "$dockerfile_path" "$DOCKERFILE")
if [ "$http_code" != 200 ]; then
  echo "No Dockerfile is fetched. Server responds $http_code"
  exit 1
fi
http_code=$(curl -s -S -L -w "%{\http_code}" --output "$dockerfile_path.dockerignore.tmp" "$DOCKERFILE.dockerignore")
if [ "$http_code" = 200 ]; then
  echo "Fetched .dockerignore from $DOCKERFILE.dockerignore"
  mv "$dockerfile_path.dockerignore.tmp" "$SOURCE_CODE_DIR/$CONTEXT/.dockerignore"
fi
else
echo "Cannot find Dockerfile $DOCKERFILE"
exit 1
fi
dockerfile_copy=$(mktemp --tmpdir "$(basename "$dockerfile_path").XXXXXX")
cp "$dockerfile_path" "$dockerfile_copy"
# Inject the image content manifest into the container we are producing.
# This will generate the content-sets.json file and copy it by appending a COPY
# instruction to the Containerfile.
inject-icm-to-containerfile "$dockerfile_copy" "/var/workdir/cachi2/output/bom.json" "$SOURCE_CODE_DIR/$CONTEXT"
echo "[$(date --utc -Ins)] Prepare system (architecture: $(uname -m))"
# Fixing group permission on /var/lib/containers
chown root:root /var/lib/containers
sed -i 's/^\s*short-name-mode\s*=\s*.*/short-name-mode = "disabled"/' /etc/containers/registries.conf
# Setting new namespace to run buildah - 2^32-2
echo 'root:1:4294967294' | tee -a /etc/subuid >> /etc/subgid
build_args=()
if [ -n "${BUILD_ARGS_FILE}" ]; then
# Parse BUILD_ARGS_FILE ourselves because dockerfile-json doesn't support it
echo "Parsing ARGs from $BUILD_ARGS_FILE"
mapfile -t build_args < <(
  # https://www.mankier.com/1/buildah-build#--build-arg-file
  # delete lines that start with #
  # delete blank lines
  sed -e '/^#/d' -e '/^\s*$/d' "${SOURCE_CODE_DIR}/${BUILD_ARGS_FILE}"
)
fi
LABELS=()
ANNOTATIONS=()
# Append any annotations from the specified file
if [ -n "${ANNOTATIONS_FILE}" ] && [ -f "${SOURCE_CODE_DIR}/${ANNOTATIONS_FILE}" ]; then
echo "Reading annotations from file: ${SOURCE_CODE_DIR}/${ANNOTATIONS_FILE}"
while IFS= read -r line || [[ -n "$line" ]]; do
  # Skip empty lines and comments
  if [[ -n "$line" && ! "$line" =~ ^[[:space:]]*# ]]; then
    ANNOTATIONS+=("--annotation" "$line")
  fi
done < "${SOURCE_CODE_DIR}/${ANNOTATIONS_FILE}"
fi
# Split `args` into two sets of arguments.
while [[ $# -gt 0 ]]; do
  case $1 in
      --build-args)
          shift
          # Note: this may result in multiple --build-arg=KEY=value flags with the same KEY being
          # passed to buildah. In that case, the *last* occurrence takes precedence. This is why
          # we append BUILD_ARGS after the content of the BUILD_ARGS_FILE
          while [[ $# -gt 0 && $1 != --* ]]; do build_args+=("$1"); shift; done
          ;;
      --labels)
          shift
          while [[ $# -gt 0 && $1 != --* ]]; do LABELS+=("--label" "$1"); shift; done
          ;;
      --annotations)
          shift
          while [[ $# -gt 0 && $1 != --* ]]; do ANNOTATIONS+=("--annotation" "$1"); shift; done
          ;;
      *)
          echo "unexpected argument: $1" >&2
          exit 2
          ;;
  esac
done
BUILD_ARG_FLAGS=()
for build_arg in "${build_args[@]}"; do
BUILD_ARG_FLAGS+=("--build-arg=$build_arg")
done
dockerfile-json "${BUILD_ARG_FLAGS[@]}" "$dockerfile_copy" > /shared/parsed_dockerfile.json
mapfile -t BASE_IMAGES < <(
  jq -r '.Stages[] | select(.From | .Stage or .Scratch | not) | .BaseName | select(test("^oci-archive:") | not)' /shared/parsed_dockerfile.json |
    tr -d '"' |
    tr -d "'"
)
BUILDAH_ARGS=()
UNSHARE_ARGS=()
if [ "${HERMETIC}" == "true" ]; then
BUILDAH_ARGS+=("--pull=never")
UNSHARE_ARGS+=("--net")
for image in "${BASE_IMAGES[@]}"; do
  unshare -Ufp --keep-caps -r --map-users 1,1,65536 --map-groups 1,1,65536 --mount -- buildah pull "$image"
done
echo "Build will be executed with network isolation"
fi
if [ -n "${TARGET_STAGE}" ]; then
BUILDAH_ARGS+=("--target=${TARGET_STAGE}")
fi
BUILDAH_ARGS+=("${BUILD_ARG_FLAGS[@]}")
# Necessary for newer version of buildah if the host system does not contain up to date version of container-selinux
# TODO remove the option once all hosts were updated
BUILDAH_ARGS+=("--security-opt=unmask=/proc/interrupts")
if [ "${PRIVILEGED_NESTED}" == "true" ]; then
BUILDAH_ARGS+=("--security-opt=label=disable")
BUILDAH_ARGS+=("--cap-add=all")
BUILDAH_ARGS+=("--device=/dev/fuse")
fi
if [ -n "${ADD_CAPABILITIES}" ]; then
BUILDAH_ARGS+=("--cap-add=${ADD_CAPABILITIES}")
fi
if [ "${SQUASH}" == "true" ]; then
BUILDAH_ARGS+=("--squash")
fi
if [ "${SKIP_UNUSED_STAGES}" != "true" ] ; then
BUILDAH_ARGS+=("--skip-unused-stages=false")
fi
if [ "${INHERIT_BASE_IMAGE_LABELS}" != "true" ] ; then
BUILDAH_ARGS+=("--inherit-labels=false")
fi
VOLUME_MOUNTS=()
echo "[$(date --utc -Ins)] Setup prefetched"
if [ -f "$(workspaces.source.path)/cachi2/cachi2.env" ]; then
cp -r "$(workspaces.source.path)/cachi2" /tmp/
chmod -R go+rwX /tmp/cachi2
VOLUME_MOUNTS+=(--volume /tmp/cachi2:/cachi2)
# Read in the whole file (https://unix.stackexchange.com/questions/533277), then
# for each RUN ... line insert the cachi2.env command *after* any options like --mount
sed -E -i \
    -e 'H;1h;$!d;x' \
    -e 's@^\s*(run((\s|\\\n)+-\S+)*(\s|\\\n)+)@\1. /cachi2/cachi2.env && \\\n    @igM' \
    "$dockerfile_copy"
echo "Prefetched content will be made available"
prefetched_repo_for_my_arch="/tmp/cachi2/output/deps/rpm/$(uname -m)/repos.d/cachi2.repo"
if [ -f "$prefetched_repo_for_my_arch" ]; then
  echo "Adding $prefetched_repo_for_my_arch to $YUM_REPOS_D_FETCHED"
  mkdir -p "$YUM_REPOS_D_FETCHED"
  if [ ! -f "${YUM_REPOS_D_FETCHED}/cachi2.repo" ]; then
    cp "$prefetched_repo_for_my_arch" "$YUM_REPOS_D_FETCHED"
  fi
fi
fi
# if yum repofiles stored in git, copy them to mount point outside the source dir
if [ -d "${SOURCE_CODE_DIR}/${YUM_REPOS_D_SRC}" ]; then
mkdir -p "${YUM_REPOS_D_FETCHED}"
cp -r "${SOURCE_CODE_DIR}/${YUM_REPOS_D_SRC}"/* "${YUM_REPOS_D_FETCHED}"
fi
# if anything in the repofiles mount point (either fetched or from git), mount it
if [ -d "${YUM_REPOS_D_FETCHED}" ]; then
chmod -R go+rwX "${YUM_REPOS_D_FETCHED}"
mount_point=$(realpath "${YUM_REPOS_D_FETCHED}")
VOLUME_MOUNTS+=(--volume "${mount_point}:${YUM_REPOS_D_TARGET}")
fi
DEFAULT_LABELS=(
"--label" "build-date=$(date -u +'%Y-%m-%dT%H:%M:%S')"
"--label" "architecture=$(uname -m)"
"--label" "vcs-type=git"
)
[ -n "$COMMIT_SHA" ] && DEFAULT_LABELS+=("--label" "vcs-ref=$COMMIT_SHA")
[ -n "$IMAGE_EXPIRES_AFTER" ] && DEFAULT_LABELS+=("--label" "quay.expires-after=$IMAGE_EXPIRES_AFTER")
# Concatenate defaults and explicit labels. If a label appears twice, the last one wins.
LABELS=("${DEFAULT_LABELS[@]}" "${LABELS[@]}")
echo "[$(date --utc -Ins)] Register sub-man"
ACTIVATION_KEY_PATH="/activation-key"
ENTITLEMENT_PATH="/entitlement"
# 0. if hermetic=true, skip all subscription related stuff
# 1. do not enable activation key and entitlement at same time. If both vars are provided, prefer activation key.
# 2. Activation-keys will be used when the key 'org' exists in the activation key secret.
# 3. try to pre-register and mount files to the correct location so that users do no need to modify Dockerfiles.
# 3. If the Dockerfile contains the string "subcription-manager register", add the activation-keys volume
#    to buildah but don't pre-register for backwards compatibility. Mount an empty directory on
#    shared emptydir volume to "/etc/pki/entitlement" to prevent certificates from being included
if [ "${HERMETIC}" != "true" ] && [ -e /activation-key/org ]; then
cp -r --preserve=mode "$ACTIVATION_KEY_PATH" /tmp/activation-key
mkdir -p /shared/rhsm/etc/pki/entitlement
mkdir -p /shared/rhsm/etc/pki/consumer
VOLUME_MOUNTS+=(-v /tmp/activation-key:/activation-key \
                -v /shared/rhsm/etc/pki/entitlement:/etc/pki/entitlement:Z \
                -v /shared/rhsm/etc/pki/consumer:/etc/pki/consumer:Z)
echo "Adding activation key to the build"
if ! grep -E "^[^
]*subscription-manager.[^
]*register" "$dockerfile_path"; then
  # user is not running registration in the Containerfile: pre-register.
  echo "Pre-registering with subscription manager."
  subscription-manager register --org "$(cat /tmp/activation-key/org)" --activationkey "$(cat /tmp/activation-key/activationkey)"
  trap 'subscription-manager unregister || true' EXIT
  # copy generated certificates to /shared volume
  cp /etc/pki/entitlement/*.pem /shared/rhsm/etc/pki/entitlement
  cp /etc/pki/consumer/*.pem /shared/rhsm/etc/pki/consumer
  # and then mount get /etc/rhsm/ca/redhat-uep.pem into /run/secrets/rhsm/ca
  VOLUME_MOUNTS+=(--volume /etc/rhsm/ca/redhat-uep.pem:/etc/rhsm/ca/redhat-uep.pem:Z)
fi
elif [ "${HERMETIC}" != "true" ] && find /entitlement -name "*.pem" >> null; then
cp -r --preserve=mode "$ENTITLEMENT_PATH" /tmp/entitlement
VOLUME_MOUNTS+=(--volume /tmp/entitlement:/etc/pki/entitlement)
echo "Adding the entitlement to the build"
fi
if [ -n "$WORKINGDIR_MOUNT" ]; then
if [[ "$WORKINGDIR_MOUNT" == *:* ]]; then
  echo "WORKINGDIR_MOUNT contains ':'" >&2
  echo "Refusing to proceed in case this is an attempt to set unexpected mount options." >&2
  exit 1
fi
# ${SOURCE_CODE_DIR}/${CONTEXT} will be the $PWD when we call 'buildah build'
# (we set the workdir using 'unshare -w')
context_dir=$(realpath "${SOURCE_CODE_DIR}/${CONTEXT}")
VOLUME_MOUNTS+=(--volume "$context_dir:${WORKINGDIR_MOUNT}")
fi
if [ -n "${ADDITIONAL_VOLUME_MOUNTS-}" ]; then
# ADDITIONAL_VOLUME_MOUNTS allows to specify more volumes for the build.
# Instrumented builds (SAST) use this step as their base and add some other tools.
while read -r volume_mount; do
  VOLUME_MOUNTS+=("--volume=$volume_mount")
done <<< "${ADDITIONAL_VOLUME_MOUNTS}"
fi
echo "[$(date --utc -Ins)] Add secrets"
ADDITIONAL_SECRET_PATH="/additional-secret"
ADDITIONAL_SECRET_TMP="/tmp/additional-secret"
if [ -d "$ADDITIONAL_SECRET_PATH" ]; then
cp -r --preserve=mode -L "$ADDITIONAL_SECRET_PATH" $ADDITIONAL_SECRET_TMP
while read -r filename; do
  echo "Adding the secret ${ADDITIONAL_SECRET}/${filename} to the build, available at /run/secrets/${ADDITIONAL_SECRET}/${filename}"
  BUILDAH_ARGS+=("--secret=id=${ADDITIONAL_SECRET}/${filename},src=$ADDITIONAL_SECRET_TMP/${filename}")
done < <(find $ADDITIONAL_SECRET_TMP -maxdepth 1 -type f -exec basename {} \;)
fi
# Prevent ShellCheck from giving a warning because 'image' is defined and 'IMAGE' is not.
declare IMAGE
buildah_cmd_array=(
  buildah build
  "${VOLUME_MOUNTS[@]}"
  "${BUILDAH_ARGS[@]}"
  "${LABELS[@]}"
  "${ANNOTATIONS[@]}"
  --tls-verify="$TLSVERIFY" --no-cache
  --ulimit nofile=4096:4096
  -f "$dockerfile_copy" -t "$IMAGE" .
)
buildah_cmd=$(printf "%q " "${buildah_cmd_array[@]}")
if [ "${HERMETIC}" == "true" ]; then
# enabling loopback adapter enables Bazel builds to work in hermetic mode.
command="ip link set lo up && $buildah_cmd"
else
command="$buildah_cmd"
fi
# disable host subcription manager integration
find /usr/share/rhel/secrets -type l -exec unlink {} \;
echo "[$(date --utc -Ins)] Run buildah build"
echo "[$(date --utc -Ins)] ${command}"
unshare -Uf "${UNSHARE_ARGS[@]}" --keep-caps -r --map-users 1,1,65536 --map-groups 1,1,65536 -w "${SOURCE_CODE_DIR}/$CONTEXT" --mount -- sh -c "$command"
echo "[$(date --utc -Ins)] Add metadata"
# Save the SBOM produced by Cachi2 so it can be merged into the final SBOM later
if [ -f "/tmp/cachi2/output/bom.json" ]; then
echo "Making copy of sbom-cachi2.json"
cp /tmp/cachi2/output/bom.json ./sbom-cachi2.json
fi
touch /shared/base_images_digests
echo "Recording base image digests used"
for image in "${BASE_IMAGES[@]}"; do
base_image_digest=$(buildah images --format '{{ .Name }}:{{ .Tag }}@{{ .Digest }}' --filter reference="$image")
# In some cases, there might be BASE_IMAGES, but not any associated digest. This happens
# if buildah did not use that particular image during build because it was skipped
if [ -n "$base_image_digest" ]; then
  echo "$image $base_image_digest" | tee -a /shared/base_images_digests
fi
done
image_name=$(echo "${IMAGE##*/}" | tr ':' '-')
buildah push "$IMAGE" oci:"/shared/$image_name.oci"
echo "/shared/$image_name.oci" > /shared/container_path
echo "[$(date --utc -Ins)] End build"

