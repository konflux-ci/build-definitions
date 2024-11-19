# eaas-get-ephemeral-cluster-credentials stepaction

This StepAction queries the EaaS hub cluster to get the kubeconfig for an ephemeral cluster by name. Credentials are stored in a mounted volume that must be provided as a param.

## Parameters
|name|description|default value|required|
|---|---|---|---|
|eaasSpaceSecretRef|Name of a secret containing credentials for accessing an EaaS space.||true|
|clusterName|The name of a ClusterTemplateInstance.||true|
|credentials|A volume to which the remote cluster credentials will be written.||true|
|insecureSkipTLSVerify|Skip TLS verification when accessing the EaaS hub cluster. This should not be set to "true" in a production environment.|false|false|

## Results
|name|description|
|---|---|
|kubeconfig|Relative path to the kubeconfig in the mounted volume|
|username|The username for the cluster|
|passwordPath|Relative path to the password file in the mounted volume|
|apiServerURL|API server URL of the cluster|
|consoleURL|Console URL of the cluster|

