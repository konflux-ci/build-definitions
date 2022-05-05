
# Each argument will become a directory, e.g. if you call it like this:
#  json-data-file foo bar 123
#
# The result will be this:
#  $DATA_DIR/foo/bar/123/data.json
#
json-data-file() {
  local dir="$DATA_DIR"

  for d in "$@"; do
    dir="$dir/$d"
  done

  # This can result in empty dirs if the file is
  # prepared but not actually used but that's okay.
  mkdir -p "$dir"

  file="$dir/data.json"

  # Better not silently overwrite data
  [[ -f $file ]] && echo "ERROR: Name clash for $file!" 1>&2 && return 1

  echo "$file"
}

clear-data() {
  rm -rf "$DATA_DIR"
}

clear-policies() {
  rm -rf "$POLICIES_DIR"
}

# https://unix.stackexchange.com/questions/35832/how-do-i-get-the-md5-sum-of-a-directorys-contents-as-one-sum
dir-checksum() {
  local dir=$1
  find "$dir" -type f -exec sha256sum {} \; | sort -k 2 | sha256sum | cut -d' ' -f1
}

# List all the data files
show-data() {
  echo "sha256sum: $( dir-checksum "$DATA_DIR" )"
  find "$DATA_DIR" -type f
}

# List all the rego files
show-policies() {
  echo "sha256sum: $( dir-checksum "$POLICIES_DIR" )"
  find "$POLICIES_DIR" -type f
}
