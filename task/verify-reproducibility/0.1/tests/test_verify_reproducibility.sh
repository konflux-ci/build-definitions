#!/usr/bin/env bash
set -uo pipefail

PASS=0
FAIL=0

GREEN='\033[0;32m'
RED='\033[0;31m'
RESET='\033[0m'

pass() { echo -e "${GREEN}[PASS]${RESET} $1"; ((PASS++)); }
fail() { echo -e "${RED}[FAIL]${RESET} $1"; ((FAIL++)); }

run_verify_step() {
  local image1="$1"
  local image2="$2"
  local diff_out
  diff_out=$(mktemp)

  set +e
  if command -v diffoscope &>/dev/null; then
    diffoscope "$image1" "$image2" > "$diff_out" 2>&1
  else
    diff -rq "$image1" "$image2" > "$diff_out" 2>&1
  fi
  set -e

  if [ -s "$diff_out" ]; then
    rm -f "$diff_out"
    echo "FAILURE"
  else
    rm -f "$diff_out"
    echo "SUCCESS"
  fi
}

echo "=== Test 1: identical directories → expect SUCCESS ==="
DIR_A=$(mktemp -d)
DIR_B=$(mktemp -d)
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

echo ""
echo "=== Test 2: different file content → expect FAILURE ==="
DIR_A=$(mktemp -d)
DIR_B=$(mktemp -d)
echo "hello" > "$DIR_A/file.txt"
echo "world" > "$DIR_B/file.txt"
RESULT=$(run_verify_step "$DIR_A" "$DIR_B")
if [ "$RESULT" = "FAILURE" ]; then
  pass "Different directories reported FAILURE"
else
  fail "Different directories reported $RESULT instead of FAILURE"
fi
rm -rf "$DIR_A" "$DIR_B"

echo ""
echo "=== Test 3: extra file in image 2 → expect FAILURE ==="
DIR_A=$(mktemp -d)
DIR_B=$(mktemp -d)
echo "same" > "$DIR_A/common.txt"
echo "same" > "$DIR_B/common.txt"
echo "extra" > "$DIR_B/extra.txt"
RESULT=$(run_verify_step "$DIR_A" "$DIR_B")
if [ "$RESULT" = "FAILURE" ]; then
  pass "Extra file detected as FAILURE"
else
  fail "Extra file reported $RESULT instead of FAILURE"
fi
rm -rf "$DIR_A" "$DIR_B"

echo ""
echo "────────────────────────────────────────"
echo "Results: ${PASS} passed, ${FAIL} failed"
echo "────────────────────────────────────────"

if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
