# Migration from 0.1 to 0.2

The parameters `BUILDER-IMAGE`, `DOCKER_AUTH` and `MAVEN_MIRROR_URL` used by `s2i-nodejs` task were removed.

## Action from users

Update files in Pull-Request created by RHTAP bot:
- Search for the task named `s2i-nodejs`
- Remove the `BUILDER-IMAGE` and `DOCKER_AUTH` and `MAVEN_MIRROR_URL`  parameters from the params section
