#shellcheck shell=bash disable=SC2154

set -o errexit
set -o pipefail
set -o nounset

print_error() {
    message="${field_note}${field_note:+: }${field_message}%0A${field_failure_message//$'\n'/%0A}"
    printf "::error file=%s,line=%d,endLine=%d,title=%s::%s%%0A" "${field_specfile}" "${field_lineno%-*}" "${field_lineno#*-}" "${field_message}" "${message}"
}

github_each() {
    case "${field_type}" in
        statement)
            [[ "$field_fail" ]] && print_error
            ;;
        error)
            print_error
            ;;
    esac
}
