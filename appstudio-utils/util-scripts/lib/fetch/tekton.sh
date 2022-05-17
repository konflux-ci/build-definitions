
##----------------------------------------------------
## NB: Some, but not all, of these methods are unused
## but I don't want to delete them just yet.
##----------------------------------------------------

pr_get_tr_names() {
  local pr=$1
  oc get pr/$pr -o json | jq -r '.status.taskRuns|keys|.[]'
}

tr_get_annotation() {
  local tr=$1
  local key=$2

  # escape dots
  key=$( echo "$key" | sed 's/\./\\\./g' )

  oc get tr/$tr -o jsonpath="{.metadata.annotations.$key}"
}

tr_get_result() {
  local tr=$1
  local key=$2
  oc get tr/$tr -o jsonpath="{.status.taskResults[?(@.name == \"$key\")].value}"
}

tr_get_task_name() {
  local tr=$1
   oc get tr/$tr -o jsonpath="{.metadata.labels['tekton\.dev/pipelineTask']}"
}

tr_transparency_url() {
  local tr=$1
  tr_get_annotation $tr 'chains.tekton.dev/transparency'
}

tr_image_digest() {
  # The transparency log entry for the image digest
  tr_get_result $tr IMAGE_DIGEST | cut -d: -f2
}

tr_save_transparency_log() {
  local tr=$1

  url=$( tr_transparency_url $tr )
  [[ -n $url ]] && rekor_log_entry_save_from_url $url

  true # because of set -e
}

tr_save_digest_logs() {
  local tr=$1

  digest=$( tr_image_digest $tr )
  url=$( tr_transparency_url $tr ) # (needed only to find the rekor_host)
  [[ -n $digest ]] && [[ -n $url ]] && rekor_digest_save "$digest" "$url"

  true # because of set -e
}
