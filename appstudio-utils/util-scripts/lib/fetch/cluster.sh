
k8s-save-data() {
  local kind=$1
  local name=$2
  local namespace=${3:-}

  local namespace_opt=
  [[ -n $namespace ]] && namespace_opt="-n$namespace"

  local file=$( json-data-file cluster $kind $name )

  echo "Saving $kind $name $namespace_opt"
  oc get $namespace_opt $kind $name -o json > $file
}

_policy-config-from-configmap() {
  oc get configmap ec-policy -o go-template='{{index .data "policy.json"}}' 2>/dev/null
}

_default-policy-config() {
  echo '{"non_blocking_checks":["not_useful"]}'
}

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

# If given $1, looks up the ECP custom resource
save-policy-config() {
  local namespace_arg
  namespace_arg=$(cr-namespace-argument "${1:-}")
  local args
  args=(${namespace_arg} "$(cr-name "${1:-}")") # intentionally not quoting the $namespace_arg so it expands

  local config_file
  config_file="$DATA_DIR/config.json"
  mkdir -p $DATA_DIR

  local non_blocking_data
  if ! non_blocking_data=$(kubectl get enterprisecontractpolicies.appstudio.redhat.com "${args[*]}" -o jsonpath='{.spec.exceptions.nonBlocking}'); then
    local namespace=${namespace_arg#-n }
    echo "ERROR: unable to find the ec-policy EnterpriseContractPolicy in namespace ${namespace:-$(kubectl config view --minify -o jsonpath='{..namespace}')}" 1>&2
  else
    if [[ -z "${non_blocking_data}" ]]; then
      non_blocking_data='[]'
    fi
    # Save the config data from the ECP
    echo "$non_blocking_data" | jq '{"config": {"policy": {"non_blocking_checks": . }}}' > "${config_file}"
    return 0
  fi

  # If the ECP isn't there, fall back to use either the configmap or the defaults
  # TODO remove the below lines once the demos don't depend on this
  # Note: the namespace the task is running in needs to have the ec-policy ConfigMap
  { _policy-config-from-configmap || _default-policy-config ; } | jq '{"config": {"policy": . }}' > "${config_file}"
}
