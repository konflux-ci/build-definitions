#!/usr/bin/bash
set -euo pipefail

# (For troubleshooting and debugging only)

EC_WORK_DIR=${EC_WORK_DIR:-/tmp/ecwork}
DATA_DIR=${DATA_DIR:-"$EC_WORK_DIR/data"}

print-data() {
  # Ignore stdout since we want the print output on stderr
  opa eval --data "$DATA_DIR" 'print(data)' 2>&1 >/dev/null
}

if [[ ${1:-} == 'files' ]]; then
  # Just show the files
  find "$DATA_DIR" -type f

elif [[ ${1:-} == 'keys' ]]; then
  # Useful to see the structure
  print-data | jq -r 'paths | join(" › ")'

elif [[ ${1:-} == 'yaml' ]]; then
  # If you prefer yaml
  print-data | yq e -P -

else
  # Show the huge object with all data
  print-data | jq

fi
