# Migration from 0.1 to 0.2

The parameters `skip-optional`, `pipelinerun-name` and ` pipelinerun-uid` used by `init` task were removed.

## Action from users

Update files in Pull-Request created by RHTAP bot:
- Search for the task named `init`
- Remove the `skip-optional`, `pipelinerun-name` and ` pipelinerun-uid` parameters from the params section


# Migration from 0.2 to 0.2.1

OpenShift's documentation indicates that disconnected clusters can
use any container registry that supports Docker v2-2. This means that
disconnected mirroring will fail if the registry doesn't support OCI.

https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html/disconnected_environments/connected-to-disconnected

Thus, to support old workflows, we are migrating globally back to docker format, and then project by project should decide when to use OCI again.

FBC builds should continue using `oci` format.

## Action from users

Change `BUILDAH_FORMAT` param value to `docker` in build related tasks: build-images, build-container, build-image-index (build-image-manifest eventually).

If your project require OCI, you don't need to do change (However, check automatic migration if it didn't migrate you to docker format).

# Migration from 0.2.3 to 0.2.4

The `init` task now supports cache proxy configuration through a new `enable-cache-proxy` parameter. When enabled, the init task outputs proxy configuration values (`http-proxy` and `no-proxy` results) that can be consumed by build tasks like `buildah`.

This enables builds to use a caching proxy to reduce network traffic and improve build performance.

## Automatic Migration

The migration script (`0.2.4.sh`) automatically performs the following:

1. **Adds `enable-cache-proxy` parameter** to the pipeline with a default value of `"false"` to maintain backward compatibility
2. **Adds `enable-cache-proxy` parameter** to the `init` task, passing the pipeline parameter value
3. **Adds `HTTP_PROXY` and `NO_PROXY` parameters** to all buildah-related tasks (including `buildah`, `buildah-remote`, `buildah-oci-ta`, `buildah-remote-oci-ta`, and `buildah-min`) that reference the init task's proxy results:
   ```yaml
   - name: HTTP_PROXY
     value: $(tasks.init.results.http-proxy)
   - name: NO_PROXY
     value: $(tasks.init.results.no-proxy)
   ```

The migration script is idempotent and will skip tasks that already have these parameters configured.

## Action from users

No action required. The migration script automatically handles all necessary changes.

If you want to enable cache proxy for your builds, set the `enable-cache-proxy` parameter to `"true"` in your pipeline configuration. The proxy configuration will then be automatically passed to all buildah tasks.

# Migration from 0.2.4 to 0.2.5

This is a fix made to 0.2.4 version migration script.
The migration script failed to detect variations of buildah task and therefore did not update them

## Action from users

No action required. The migration script automatically handles all necessary changes.
