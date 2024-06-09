# eaas-get-supported-ephemeral-cluster-versions stepaction

This StepAction queries the EaaS hub cluster used to provision ephemeral clusters for testing. It returns a list of supported versions stored in a hypershift ConfigMap.

## Parameters
|name|description|default value|required|
|---|---|---|---|
|eaasSpaceSecretRef|Name of a secret containing credentials for accessing an EaaS space.||true|
|insecureSkipTLSVerify|Skip TLS verification when accessing the EaaS hub cluster. This should not be set to "true" in a production environment.|false|false|

## Results
|name|description|
|---|---|
|versions|List of supported minor versions from newest to oldest. E.g. ["4.15","4.14","4.13"]|

