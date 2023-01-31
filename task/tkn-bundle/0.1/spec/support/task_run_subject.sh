#!/bin/env bash

set -o errexit
set -o pipefail
set -o nounset

shellspec_syntax 'shellspec_subject_taskrun'

shellspec_subject_taskrun() {
  # shellcheck disable=SC2034
  SHELLSPEC_META='text'
  shellspec_readfile_once SHELLSPEC_STDOUT "$SHELLSPEC_STDOUT_FILE"
  if [ ${SHELLSPEC_STDOUT+x} ]; then
    # shellcheck disable=SC2034
    LINES=(${SHELLSPEC_STDOUT[@]})
    TASK_RUN_NAME="${LINES[2]}" # "TaskRun(0) started:(1) tkn-bundle-run-ndjfb(2)
    SHELLSPEC_SUBJECT="$(tkn tr describe "${TASK_RUN_NAME}" -o json)"
    shellspec_chomp SHELLSPEC_SUBJECT
  else
    unset SHELLSPEC_SUBJECT ||:
  fi

  shellspec_off UNHANDLED_STDOUT

  eval shellspec_syntax_dispatch modifier ${1+'"$@"'}
}
