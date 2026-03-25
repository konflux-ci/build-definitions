# Tests for `verify-reproducibility` Task

This directory contains local tests for the
[`verify-reproducibility`](../verify-reproducibility.yaml) Tekton task.

## What is tested?

The task compares two container images using **diffoscope** and emits a
`TEST_OUTPUT` result of `SUCCESS` or `FAILURE`.

The test script (`test_verify_reproducibility.sh`) mimics the task's
`diffoscope-verify` step logic using local temporary directories:

| # | Scenario | Expected result |
|---|---|---|
| 1 | Two identical directory trees | `SUCCESS` |
| 2 | Directories with differing file content | `FAILURE` |
| 3 | One directory has an extra file | `FAILURE` |

## Prerequisites

Install `diffoscope` locally:

```bash
# Fedora / RHEL
sudo dnf install diffoscope

# Ubuntu / Debian
sudo apt install diffoscope

# macOS
brew install diffoscope

# Or use the official container image (no local install needed)
docker run --rm -it ghcr.io/reproducible-builds/diffoscope:latest --help
```

## Running the tests

```bash
cd task/verify-reproducibility/0.1/tests
bash test_verify_reproducibility.sh
```

Expected output when all tests pass:

```
=== Test 1: identical OCI-like directories → expect SUCCESS ===
[PASS] Identical directories reported SUCCESS

=== Test 2: different OCI-like directories → expect FAILURE ===
[PASS] Different directories reported FAILURE

=== Test 3: extra file in image 2 → expect FAILURE ===
[PASS] Extra file detected as FAILURE

────────────────────────────────────────
Results: 3 passed, 0 failed
────────────────────────────────────────
```

## Running via container (no local diffoscope needed)

```bash
docker run --rm \
  -v "$PWD:/work" \
  ghcr.io/reproducible-builds/diffoscope:latest \
  /work/task/verify-reproducibility/0.1/tests/test_verify_reproducibility.sh
```

> **Note**: The tests are intentionally lightweight and do not require a
> running Kubernetes/Tekton cluster. End-to-end cluster tests are tracked
> separately.
