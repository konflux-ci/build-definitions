# eaas-get-latest-openshift-version-by-prefix stepaction

This StepAction queries an OpenShift CI API to get the latest version for a release stream.

## Parameters
|name|description|default value|required|
|---|---|---|---|
|prefix|The leading part of the OpenShift version. E.g. `4.` or `4.15.`||true|
|releaseStream|The name of the OpenShift release stream. E.g. `4-stable`|4-stable|false|

## Results
|name|description|
|---|---|
|version|The latest matching version.|

