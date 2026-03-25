#!/usr/bin/env bash
# test_verify_reproducibility.sh
#
# Local integration test for the verify-reproducibility task logic.
# Simulates the diffoscope comparison step using two temporary directories
# that either are identical (SUCCESS) or have differences (FAILURE).
#
# Usage:
#   bash test_verify_reproducibility.sh
#
# Requirements: diffoscope installed locally  OR  running via the container
#   docker run --rm -v "$PWD:/work" ghcr.io/reproducible-builds/diffoscope:latest ...
#
# Exit codes:
#   0  – all test cases passed
#   1  – one or more test cases failed

set -euo pipefail

PASS=0
FAIL=0

# ─── helpers ────────────────────────────────────────────────────────────────

GREEN='\033[0;32m'
RED='\033[0;31m'
RESET='\033[0m'

pass() { echo -e "${GREEN}[PASS]${RESET} $1"; ((PASS++)); }
fail() { echo -e "${RED}[FAIL]${RESET} $1"; ((FAIL++)); }

# Mimic the task's diffoscope-verify step logic.
# Arguments:
#   $1 – path to "image 1" directory
#   $2 – path to "image 2" directory
# Returns the result string: SUCCESS or FAILURE
run_verify_step() {
  local image1="$1"
  local image2="$2"
  local diff_out
  diff_out=$(mktemp)

  diffoscope "$image1" "$image2" > "$diff_out" 2>&1 || true

  if [ -s "$diff_out" ]; then
    echo "FAILURE"
  else
    echo "SUCCESS"
  fi

  rm -f "$diff_out"
}

# ─── test 1: identical directories ──────────────────────────────────────────

echo "=== Test 1: identical OCI-like directories → expect SUCCESS ==="

DIR_A=$(mktemp -d)
DIR_B=$(mktemp -d)

# Populate both directories with the same content
echo "FROM scratch" > "$DIR_A/Dockerfile"
echo "FROM scratch" > "$DIR_B/Dockerfile"
mkdir -p "$DIR_A/layer" "$DIR_B/layer"
echo "hello" > "$DIR_A/layer/file.txt"
echo "hello" > "$DIR_B/layer/file.txt"

RESULT=$(run_verify_step "$DIR_A" "$DIR_B")
if [ "$RESULT" = "SUCCESS" ]; then
  pass "Identical directories reported SUCCESS"
else
  fail "Identical directories reported $RESULT instead of SUCCESS"
fi

rm -rf "$DIR_A" "$DIR_B"

# ─── test 2: different directories ──────────────────────────────────────────

echo ""
echo "=== Test 2: different OCI-like directories → expect FAILURE ==="

DIR_A=$(mktemp -d)
DIR_B=$(mktemp -d)

echo "hello" > "$DIR_A/file.txt"
echo "world" > "$DIR_B/file.txt"  # different content

RESULT=$(run_verify_step "$DIR_A" "$DIR_B")
if [ "$RESULT" = "FAILURE" ]; then
  pass "Different directories reported FAILURE"
else
  fail "Different directories reported $RESULT instead of FAILURE"
fi

rm -rf "$DIR_A" "$DIR_B"

# ─── test 3: missing file in one image ──────────────────────────────────────

echo ""
echo "=== Test 3: extra file in image 2 → expect FAILURE ==="

DIR_A=$(mktemp -d)
DIR_B=$(mktemp -d)

echo "same" > "$DIR_A/common.txt"
echo "same" > "$DIR_B/common.txt"
echo "extra" > "$DIR_B/extra.txt"  # only in image 2

RESULT=$(run_verify_step "$DIR_A" "$DIR_B")
if [ "$RESULT" = "FAILURE" ]; then
  pass "Extra file detected as FAILURE"
else
  fail "Extra file reported $RESULT instead of FAILURE"
fi

rm -rf "$DIR_A" "$DIR_B"

# ─── summary ────────────────────────────────────────────────────────────────

echo ""
echo "────────────────────────────────────────"
echo "Results: ${PASS} passed, ${FAIL} failed"
echo "────────────────────────────────────────"

if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
