
# Use rekor-cli to fetch one log entry
rekor-log-entry() {
  local log_index=$1
  local rekor_host=${2:-rekor.sigstore.dev}

  rekor-cli get --log-index $log_index --rekor_server https://$rekor_host --format json
}

# Same thing but lookup by uuid instead of log index
rekor-uuid-entry() {
  local uuid=$1
  local rekor_host=${2:-rekor.sigstore.dev}

  rekor-cli get --uuid $uuid --rekor_server https://$rekor_host --format json
}

# Extract the log index from a transparency url
log-index-from-url() {
  local url=$1
  # Assume it has a url param called logIndex
  perl -MURI -e '%u = URI->new(@ARGV[0])->query_form; print $u{logIndex}' "$url"
}

# Extract the rekor host from a transparency url
rekor-host-from-url() {
  local url=$1
  perl -MURI -e 'print URI->new(@ARGV[0])->host' "$url"
}

rekor-log-entry-from-url() {
  local url=$1

  rekor-log-entry $(log-index-from-url $url) $(rekor-host-from-url $url)
}

# If the rekor log entry has an attestation, extract it and
# save it separately so we can access it more conveniently
#
rekor-save-attestation-maybe() {
  local entry_data="$1"
  local att_file="$2"

  local att_data=$( echo "$entry_data" | jq -r '.Attestation' )

  if [[ -n $att_data ]] && [[ $att_data != 'null' ]] && [[ $att_data != '{}' ]]; then
    echo "Saving attestation extracted from rekor data"
    echo "$att_data" | base64 -d | jq > "$att_file"
  fi
}

# Save a transparency log entry to a json data file
# For convenience also save the attestation if there is one.
#
rekor-log-entry-save() {
  local log_index=$1
  local rekor_host=${2:-rekor.sigstore.dev}

  local entry_data=$( rekor-log-entry $log_index $rekor_host )
  local entry_file=$( json-data-file rekor $rekor_host index $log_index entry )
  local att_file=$( json-data-file rekor $rekor_host index $log_index attestation )

  echo "Saving log index $log_index from $rekor_host"
  echo "$entry_data" | jq > "$entry_file"

  rekor-save-attestation-maybe "$entry_data" "$att_file"
}

rekor-log-entry-save-from-url() {
  rekor-log-entry-save $(log-index-from-url $1) $(rekor-host-from-url $1)
}

 # Just to avoid very long paths
shorten-sha() {
  local sha=$1

  echo "$sha" | sed 's|^sha[0-9/]\+:||' | head -c 11
}

rekor-digest-save() {
  local digest=$1
  local transparency_url=$2
  local rekor_host=$( rekor-host-from-url $transparency_url )

  local short_digest=$( shorten-sha $digest )
  local uuids=$( rekor-cli search --sha "$digest" --rekor_server "https://$rekor_host" 2>/dev/null )

  # It's possible to have multiple entries for a particular digest so let's save them all
  for uuid in $uuids; do
    local short_uuid=$( shorten-sha $uuid )
    local entry_file=$( json-data-file rekor $rekor_host digest $short_digest uuid $short_uuid entry )
    local att_file=$( json-data-file rekor $rekor_host digest $short_digest uuid $short_uuid attestation )

    local entry_data=$( rekor-uuid-entry $uuid $rekor_host )
    echo "Saving log uuid $short_uuid for image digest $short_digest from $rekor_host"
    echo "$entry_data" | jq > $entry_file

    rekor-save-attestation-maybe "$entry_data" "$att_file"
  done
}
