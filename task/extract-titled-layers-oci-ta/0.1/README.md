# extract-titled-layers-oci-ta task

Restore SOURCE_ARTIFACT, then fetch titled container-image layers matching
EXTRA_ARTIFACT_FILTER from image-url@image-digest into that tree and emit a
new SOURCE_ARTIFACT.

Intended for ModelCar/olot images: untitled base-image layers and
non-matching blobs (e.g. weights) are not pulled. Image indexes are
resolved to linux/amd64. SAST tasks stay unchanged and just scan the
resulting artifact.

## Parameters
|name|description|default value|required|
|---|---|---|---|
|SOURCE_ARTIFACT|Trusted Artifact URI of the git source to restore first.||true|
|image-url|Container image repository (no digest).||true|
|image-digest|Digest of the image or image index to extract from.||true|
|EXTRA_ARTIFACT_FILTER|Extended regex matched against org.opencontainers.image.title.|(^|/)(Dockerfile|Containerfile|[^/]+\.(json|jinja|py|rb|pl|js|mjs|cjs|ts|ps1|sh|bash|zsh|ksh|md|yaml|yml|txt|model))$|false|
|ociStorage|OCI repository where the output Trusted Artifact is stored.||true|
|ociArtifactExpiresAfter|Expiration for the created trusted artifact. Empty means no expiry.|""|false|
|caTrustConfigMapKey|The name of the key in the ConfigMap that contains the CA bundle data.|ca-bundle.crt|false|
|caTrustConfigMapName|The name of the ConfigMap to read CA bundle data from.|trusted-ca|false|

## Results
|name|description|
|---|---|
|SOURCE_ARTIFACT|Trusted Artifact URI with git source plus extracted titled layers.|


## Additional info

Use this before `sast-snyk-check-oci-ta` in ModelCar pipelines so Snyk scans
titled olot layers without growing the SAST Task YAML ([PSSECAUT-1601](https://redhat.atlassian.net/browse/PSSECAUT-1601)).
Untitled layers and filter misses (weights) are not pulled.

Pass the result `SOURCE_ARTIFACT` into Snyk instead of the git clone artifact.
