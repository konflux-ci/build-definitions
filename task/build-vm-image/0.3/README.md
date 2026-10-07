# build-vm-image task

Build disk images using bootc-image-builder. https://github.com/osbuild/bootc-image-builder/

## Parameters
|name|description|default value|required|
|---|---|---|---|
|PLATFORM|The platform to build on||true|
|IMAGE_APPEND_PLATFORM|Whether to append a sanitized platform architecture on the IMAGE tag|false|false|
|OUTPUT_IMAGE|The output manifest list that points to the OCI artifact of the zipped image||true|
|SOURCE_ARTIFACT|||true|
|IMAGE_TYPE|The type of VM image to build, valid values are ami, anaconda-iso, bootc-installer, gce, iso, ova, pxe-tar-xz, qcow2, raw, vhd and vmdk||true|
|BIB_CONFIG_FILE|The config file specifying what to build and the builder to build it with|bib.yaml|false|
|CONFIG_TOML_FILE|The path for the config.toml file within the source repository|""|false|
|CONFIG_TOML_OVERLAY_FILE|Optional filesystem-only TOML overlay within the source repository; requires CONFIG_TOML_FILE|""|false|
|ENTITLEMENT_SECRET|Name of secret which contains the entitlement certificates|etc-pki-entitlement|false|
|ACTIVATION_KEY|Name of secret which contains subscription activation key|activation-key|false|
|STORAGE_DRIVER|Storage driver to configure for buildah|vfs|false|
|SBOM_TYPE|The SBOM format to use for attaching the SBOM to the artifact. Valid values: spdx, cyclonedx.|spdx|false|
|SKIP_SBOM_GENERATION|Skip SBOM propagation and attachment|false|false|

## Results
|name|description|
|---|---|
|IMAGE_DIGEST|Digest of the manifest list just built|
|IMAGE_URL|Image repository where the built manifest list was pushed|
|IMAGE_REFERENCE|Image reference (IMAGE_URL + IMAGE_DIGEST)|
|SBOM_BLOB_URL|Reference of SBOM blob digest to enable digest-based verification from provenance|
|PLATFORM|OCI platform ("linux/<arch>") of the disk image built by this task run, derived from the PLATFORM param. Lets build-image-index set the platform on each child descriptor of the multi-arch index, since the artifact manifest itself carries an empty config with no platform information.|
|IMAGE_PLATFORM_MAP|Combined "<IMAGE_REFERENCE>=linux/<arch>" entry for this task run, ready to be fanned into build-image-index's IMAGE_PLATFORM_MAP parameter (one entry per matrix leg via the [*] aggregate).|


## Additional info

### Filesystem overlays

Set `CONFIG_TOML_FILE` to the base profile and optionally set
`CONFIG_TOML_OVERLAY_FILE` to a filesystem-only TOML file in the same source
repository. For example, a downstream root minimum can be supplied without
copying the base profile's provider kernel settings:

```toml
[[customizations.filesystem]]
mountpoint = "/"
minsize = "100 GiB"
```

The overlay accepts only `customizations.filesystem` entries with `mountpoint`
and `minsize`. Entries are matched by mountpoint: supplied fields override the
matching base entry, and new mountpoints are appended. Other base customizations
and filesystem entries are preserved. Duplicate mountpoints in either input
are rejected. The legacy base filesystem `size` alias is normalized to `minsize`.
The minimum is passed through to BIB, which validates size units; it is not an
exact image size or a maximum.

An overlay requires an explicit base file. Both paths must resolve within the
source workspace. Python's standard-library TOML parser reads each input once
and rejects duplicate key or table definitions. Both inputs are validated before
writing JSON. The task creates one effective JSON config outside the source
tree and mounts it as `/config.json` with `--config=/config.json`. With no overlay,
the existing `/config.toml` path and repository-root fallback are unchanged.

Run the configuration tests locally with `bash tests/test-config-overlay.sh`
from this task directory. The Tekton test pipeline runs the same tests against
the real config script, before the test hook's SBOM-specific mocks are applied.
