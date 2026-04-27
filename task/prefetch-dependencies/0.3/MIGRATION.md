# Migration from 0.2 to 0.3

* Deprecated `dev-package-managers` task parameter has been removed.
* Task backend has changed, but it should not change the functionality.

## Action from users

Please remove the `dev-package-managers` task parameter from your pipelines.

## Migration from 0.3.1 to 0.3.2

* New `enable-package-registry-proxy` parameter has been added.
* New `SERVICE_CA_TRUST_CONFIG_MAP_NAME` and `SERVICE_CA_TRUST_CONFIG_MAP_KEY` parameters have been added.

## Action from users

Add the `enable-package-registry-proxy` parameter (default `"true"`) and pass it to the prefetch-dependencies task.
The `SERVICE_CA_TRUST_CONFIG_MAP_NAME` and `SERVICE_CA_TRUST_CONFIG_MAP_KEY` parameters have default values and require no action.
