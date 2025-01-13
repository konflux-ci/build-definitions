# Migration from 0.2 to 0.3

Version 0.3:

Removes references to `jvm-build-service`
* Removes `analyse-dependencies-java-sbom` step
* Removes `SBOM_JAVA_COMPONENTS_COUNT` and `JAVA_COMMUNITY_DEPENDENCIES` results

## Action from users

Before migrating, please check if your PipelineRun definitions contain the following results:
- `JAVA_COMMUNITY_DEPENDENCIES`
- `SBOM_JAVA_COMPONENTS_COUNT`

They should look similar to this following code block:
```
    - description: ""
      name: JAVA_COMMUNITY_DEPENDENCIES
      value: $(tasks.build-container.results.JAVA_COMMUNITY_DEPENDENCIES)
```
If your PipelineRun definition contains the results, please delete them.