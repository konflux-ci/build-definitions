## fips-operator-check-step-action

This stepAction scans relatedImages of operator bundle image builds for FIPS compliance using the check-payload tool.
* The relatedImages are expected to be in a file located at `/tekton/home/unique_related_images.txt`. 
* If the check-payload scan is desired to be run with the built-in exception list, the target OCP version (`v4.x`) should be in a file located at `/tekton/home/target_ocp_version.txt`.
* It also supports replacing relatedImages pullspecs with their first mirror. In order to use that, a mapping like {"source_registry_and_repo": ["mirror_registry_and_repo"]} should be stored in a file located at `/tekton/home/related-images-map.txt`

## Results:

| name               | description                          |
|--------------------|--------------------------------------|
| TEST_OUTPUT        | Tekton task test output.             |


## Additional links:
https://github.com/openshift/check-payload