# build-vm-image task

Build disk images using bootc-image-builder. https://github.com/osbuild/bootc-image-builder/

## Parameters
|name|description|default value|required|
|---|---|---|---|
|PLATFORM|The platform to build on||true|
|IMAGE_APPEND_PLATFORM|Whether to append a sanitized platform architecture on the IMAGE tag|false|false|
|OUTPUT_IMAGE|The output manifest list that points to the OCI artifact of the zipped image||true|
|SOURCE_ARTIFACT|||true|
|IMAGE_TYPE|The type of VM image to build, valid values are iso, qcow2, gce, vhd and raw||true|
|BIB_CONFIG_FILE|The config file specifying what to build and the builder to build it with|bib.yaml|false|
|CONFIG_TOML_FILE|The path for the config.toml file within the source repository|""|false|
|ENTITLEMENT_SECRET|Name of secret which contains the entitlement certificates|etc-pki-entitlement|false|
|STORAGE_DRIVER|Storage driver to configure for buildah|vfs|false|

## Results
|name|description|
|---|---|
|IMAGE_DIGEST|Digest of the manifest list just built|
|IMAGE_URL|Image repository where the built manifest list was pushed|
|IMAGE_REFERENCE|Image reference (IMAGE_URL + IMAGE_DIGEST)|


## Additional info
