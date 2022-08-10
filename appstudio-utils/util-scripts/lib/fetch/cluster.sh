
# Splits the given string on '/' and returns the second part
cr-name() {
  echo "${1//*\//}"
}

# Checks if the given string has a '/' and if it does splits
# it on '/' and returns the "-n <first part>"
cr-namespace-argument() {
  if [[ "$1" != */* ]]; then
    return
  fi

  local namespace="${1//\/*/}"
  if [[ -n "${namespace}" ]]; then
    echo "-n ${namespace}"
  fi
}
