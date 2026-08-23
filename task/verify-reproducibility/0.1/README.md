# verify-reproducibility task

Compares the digest of a freshly rebuilt image against the digest of
the original image it's supposed to match, and reports the outcome as
a REPRODUCIBLE result plus a TEST_OUTPUT summary. Meant to run right
after a rebuild task, as the last step of the verify-reproducibility
pipeline (see ADR-0069).


## Parameters
|name|description|default value|required|
|---|---|---|---|
|ORIGINAL_IMAGE_REF|Reference (repo@sha256:...) of the original image being verified.||true|
|REBUILT_IMAGE_REF|Reference (repo@sha256:...) of the freshly rebuilt image to compare against.||true|

## Results
|name|description|
|---|---|
|REPRODUCIBLE|true if the rebuilt image's digest matches the original image's digest, false otherwise|
|TEST_OUTPUT|JSON formatted test results for the reproducibility comparison|


## Additional info
