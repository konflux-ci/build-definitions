# download-sbom-from-url-in-attestation task

Get the SBOM for an image by downloading the OCI blob referenced in the image attestation.

The input to this task (The `IMAGES` param) is a JSON string in the same format as the output
of the [gather-deploy-images][gather-deploy-images] task:

    {
      "components": [
        {"containerImage": "<image reference>"},
        {"containerImage": "<image reference>"}
        ...
      ]
    }

For each image, the task will:
* Download the provenance attestation using `cosign verify-attestation`
* Find the SBOM_BLOB_URL Tekton result in the attestation
* Download the OCI blob referenced by the url.

The task saves the SBOMs to `${SBOMS_DIR}/${image_reference}/sbom.json`. The image references
are taken verbatim from the input object. For example, the output files could be:

    sboms-workspace/registry.example.org/namespace/foo:v1.0.0/sbom.json
    sboms-workspace/registry.example.org/namespace/bar@sha256:<checksum>/sbom.json

[gather-deploy-images]: https://github.com/redhat-appstudio/build-definitions/tree/main/task/gather-deploy-images

## Parameters
|name|description|default value|required|
|---|---|---|---|
|IMAGES|JSON object containing the array of images whose SBOMs should be downloaded. See the description for more details.||true|
|SBOMS_DIR|Path to directory (relative to the 'sboms' workspace) where SBOMs should be downloaded.|.|false|
|HTTP_RETRIES|Maximum number of retries for transient HTTP(S) errors|3|false|
|PUBLIC_KEY|Public key used to verify signatures. Must be a valid k8s cosign reference, e.g. k8s://my-space/my-secret where my-secret contains the expected cosign.pub attribute.|""|false|
|REKOR_HOST|Rekor host for transparency log lookups|""|false|
|IGNORE_REKOR|Skip Rekor transparency log checks during validation.|false|false|
|TUF_MIRROR|TUF mirror URL. Provide a value when NOT using public sigstore deployment.|""|false|

## Workspaces
|name|description|optional|
|---|---|---|
|sboms|SBOMs will be downloaded to (a subdirectory of) this workspace.|false|

## Additional info
