# Migration from 0.2 to 0.3

Version 0.3:

Removes references to `jvm-build-service`
* Removes `analyse-dependencies-java-sbom` step
* Removes `SBOM_JAVA_COMPONENTS_COUNT` and `JAVA_COMMUNITY_DEPENDENCIES` results

## Action from users

The removed items are not in use, so their removal will not impact users.

A Renovate bot PR will be created with a warning icon for this task.

This is expected, and no action from users is needed.