
# Each argument will become a directory, e.g. if you call it like this:
#  json-data-file foo bar 123
#
# The result will be this:
#  $DATA_DIR/foo/bar/123/data.json
#
json-data-file() {
  rego-input-file "data" "$DATA_DIR" "$@"
}

# Each argument will become a directory, e.g. if you call it like this:
#  json-input-file foo bar 123
#
# The result will be this:
#  $INPUT_DIR/foo/bar/123/input.json
#
json-input-file() {
  rego-input-file "input" "$INPUT_DIR" "$@"

}

rego-input-file() {
  local TYPE=$1
  local DIR=$2

  for d in "${@:3}"; do
    DIR="$DIR/$d"
  done

  # This can result in empty dirs if the file is
  # prepared but not actually used but that's okay.
  mkdir -p "$dir"

  file="$dir/$TYPE.json"

  # Better not silently overwrite data
  [[ -f $file ]] && echo "Name clash for $file!" && exit 1

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
