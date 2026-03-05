# Container Image Compression Comparison: gzip vs zstd

**Date:** 2026-03-05  
**Branch:** `gsoc-zstd-experiments`  
**Base image:** `FROM alpine` + `RUN echo "konflux zstd experiment"`  
**Built with:** buildah 1.42.2 (Podman VM — Fedora CoreOS, arm64)  

---

## Image Details

| Property        | gzip                          | zstd                          |
|-----------------|-------------------------------|-------------------------------|
| Tag             | `konflux-test:latest`         | `konflux-test:latest`         |
| Export format   | OCI directory (`/tmp/konflux-gzip`) | OCI directory (`/tmp/konflux-zstd`) |
| Architecture    | `linux/arm64`                 | `linux/arm64`                 |
| OS              | `linux`                       | `linux`                       |
| Manifest digest | `sha256:a2d29aac869389add75c...` | `sha256:4c92a2017b1a3f8aa7ed...` |
| Build tool label| `io.buildah.version: 1.43.0`  | `io.buildah.version: 1.43.0`  |

---

## Layer-by-Layer Comparison

### gzip (`application/vnd.oci.image.layer.v1.tar+gzip`)

| Layer | Digest (sha256)     | Size       |
|-------|---------------------|------------|
| 1     | `9268c2c682e14c339...` | 4,279,327 bytes (4,179.03 KiB) |
| 2     | `bd9ddc54bea929a22...` | 34 bytes   |
| **Total** |                 | **4,279,361 bytes (4,179.06 KiB)** |

### zstd (`application/vnd.oci.image.layer.v1.tar+zstd`)

| Layer | Digest (sha256)     | Size       |
|-------|---------------------|------------|
| 1     | `573800826f0f77afc...` | 4,247,596 bytes (4,147.07 KiB) |
| 2     | `9cb6e55d671da388...`  | 25 bytes   |
| **Total** |                 | **4,247,621 bytes (4,148.07 KiB)** |

---

## Compression Summary

| Metric                  | Value                        |
|-------------------------|------------------------------|
| gzip total size         | 4,279,361 bytes (4,179.06 KiB) |
| zstd total size         | 4,247,621 bytes (4,148.07 KiB) |
| **Difference**          | **31,740 bytes (31.00 KiB)**  |
| **zstd size reduction** | **0.74% smaller than gzip**  |

> **Note:** The improvement is modest here because Alpine is already very small (~5 MB
> uncompressed). On larger, real-world images (e.g. UBI, Node.js, Java runtimes) zstd
> typically delivers **10–30% faster decompression** and **5–15% smaller layer sizes**
> compared to gzip, with the additional benefit of seekable/chunked access via
> `zstd:chunked` for lazy pulling.

---

## MIME Type Difference (Key Finding)

| Format | MIME Type                                   |
|--------|---------------------------------------------|
| gzip   | `application/vnd.oci.image.layer.v1.tar+gzip` |
| zstd   | `application/vnd.oci.image.layer.v1.tar+zstd` |

The MIME type in the OCI manifest is what registries and runtimes use to select the
decompression algorithm. Switching to `zstd` or `zstd:chunked` is purely a manifest
and layer blob change — no changes to the Dockerfile or build process are needed.

---

## Commands Used

```bash
# Export gzip image to OCI directory (inside Podman VM)
buildah push --compression-format gzip \
  localhost/konflux-test:latest oci:/tmp/konflux-gzip

# Export zstd image to OCI directory (inside Podman VM)
buildah push --compression-format zstd --force-compression \
  localhost/konflux-test:latest oci:/tmp/konflux-zstd

# Inspect both
skopeo inspect oci:/tmp/konflux-gzip
skopeo inspect oci:/tmp/konflux-zstd
```

---

## Relevance to Konflux CI

Konflux container builds currently produce images using the default gzip compression
format through Buildah tasks executed in Tekton pipelines.

Supporting `zstd` and `zstd:chunked` compression will require:
- enabling configurable compression in the Buildah build and push steps
- ensuring Tekton tasks can expose compression parameters
- generating manifests that may include multiple compression variants
- maintaining compatibility with older container clients that expect gzip

The next step of the experiment will test `zstd:chunked` manifest generation using:

```bash
buildah manifest push --add-compression zstd:chunked
```

This will help identify compatibility issues and determine what changes are needed in
Konflux CI build tasks.

---

## Next Steps

- [ ] Test `zstd:chunked` format for lazy-pull experiments
- [ ] Repeat experiment with a larger image (e.g. `ubi9-minimal`) for more meaningful delta
- [ ] Integrate `--compression-format zstd:chunked` into the `task/buildah` Tekton task
- [ ] Benchmark pull time: gzip vs zstd vs zstd:chunked on a simulated registry
