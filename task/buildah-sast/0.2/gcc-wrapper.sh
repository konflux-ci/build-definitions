#!/bin/bash

# assign file name for the diagnostics output
sast_dir="/shared/sast-results"
fn="$(flock "${sast_dir}" mktemp "${sast_dir}/$$-XXXX.json.raw")"

# cleanup handler
trap "rm -f '${fn}'" EXIT TERM

# run gcc and record its exit code
/usr/bin/gcc "$@" -fdiagnostics-format=json 2>"${fn}"
EC=$?

# embed source code context
/usr/libexec/csgrep-static --mode=json --event=^warning --embed-context=3 --quiet "${fn}" >"${fn%.raw}"

# preserve the exit code from gcc
exit $EC
