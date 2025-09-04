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
