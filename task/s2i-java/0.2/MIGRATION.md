# Migration from 0.1 to 0.2

The parameters `BUILDER-IMAGE` and `DOCKER_AUTH` used by `s2i-java` task were removed.

## Action from users

Update files in Pull-Request created by RHTAP bot:
- Search for the task named `s2i-java`
- Remove the `BUILDER-IMAGE` and `DOCKER_AUTH` parameters from the params section
