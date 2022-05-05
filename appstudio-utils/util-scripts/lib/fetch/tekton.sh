
##----------------------------------------------------
## NB: Some, but not all, of these methods are unused
## but I don't want to delete them just yet.
##----------------------------------------------------

pr-get-tr-names() {
  local pr=$1
  oc get pr/$pr -o json | jq -r '.status.taskRuns|keys|.[]'
}

tr-get-annotation() {
  local tr=$1
  local key=$2

  # escape dots
  key=$( echo "$key" | sed 's/\./\\\./g' )

  oc get tr/$tr -o jsonpath="{.metadata.annotations.$key}"
}

tr-get-result() {
  local tr=$1
  local key=$2
  oc get tr/$tr -o jsonpath="{.status.taskResults[?(@.name == \"$key\")].value}"
}

tr-get-task-name() {
  local tr=$1
   oc get tr/$tr -o jsonpath="{.metadata.labels['tekton\.dev/pipelineTask']}"
}

tr-transparency-url() {
  local tr=$1
  tr-get-annotation $tr 'chains.tekton.dev/transparency'
}

tr-image-digest() {
  # The transparency log entry for the image digest
  tr-get-result $tr IMAGE_DIGEST | cut -d: -f2
}

tr-save-transparency-log() {
  local tr=$1

  url=$( tr-transparency-url $tr )
  [[ -n $url ]] && rekor-log-entry-save-from-url $url

  true # because of set -e
}

tr-save-digest-logs() {
  local tr=$1

  digest=$( tr-image-digest $tr )
  url=$( tr-transparency-url $tr ) # (needed only to find the rekor_host)
  [[ -n $digest ]] && [[ -n $url ]] && rekor-digest-save "$digest" "$url"

  true # because of set -e
}
