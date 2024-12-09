## fips-operator-check-step-action

This stepAction scans relatedImages of operator bundle image builds for FIPS compliance using the check-payload tool. The relatedImages are expected to be in a file located at `/tekton/home/unique_related_images.txt`

## Results:

| name               | description                          |
|--------------------|--------------------------------------|
| TEST_OUTPUT        | Tekton task test output.             |


## Additional links:
https://github.com/openshift/check-payload