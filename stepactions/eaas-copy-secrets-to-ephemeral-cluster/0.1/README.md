# eaas-copy-secrets-to-ephemeral-cluster stepaction

This StepAction copies Secrets from the current namespace into a configurable namespace on an ephemeral cluster. The name and content of each Secret is unaltered in the process.

## Parameters
|name|description|default value|required|
|---|---|---|---|
|credentials|A volume containing credentials to the remote cluster||true|
|kubeconfig|Relative path to the kubeconfig in the mounted cluster credentials volume||true|
|namespace|The destination namespace for the secrets. The namespace must already exist.||true|
|labelSelector|A label selector identifying the secrets to be copied||true|

