# opm-render-bundles task

Create a catalog index and render the provided bundles into it

## Parameters
|name|description|default value|required|
|---|---|---|---|
|binary-image|Base image in which to use for the catalog image|registry.redhat.io/openshift4/ose-operator-registry:latest|false|
|bundle-images|Comma separated list of bundles to add||true|
|operator-name|Name of the Operator||true|
|operator-version|Version of the Operator||true|
|default-channel|The channel that subscriptions will default to if unspecified|stable|false|

## Workspaces
|name|description|optional|
|---|---|---|
|source|Workspace with the source code|false|

## Additional info
