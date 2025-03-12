# gather-cluster-resources stepaction

This StepAction runs a script to gather konflux pipeline related artifacts and includes the possibility to run a
second custom script to gather team related artifacts.

## Parameters
|name|description|default value|required|
|---|---|---|---|
|credentials|A volume containing credentials to the remote cluster||true|
|kubeconfig|Relative path to the kubeconfig in the mounted cluster credentials volume||true|
|gather-url|URL for the custom resource gathering script||false|
|artifact-dir|Relative path to where you want the artifacts to be stored||false|

