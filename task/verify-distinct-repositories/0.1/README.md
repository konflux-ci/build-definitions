# verify-distinct-repositories task

Fails if REPOSITORY_A and REPOSITORY_B are the same string. Meant to
run before a rebuild that pushes to REPOSITORY_B, to catch the case
where it was accidentally set to the same repository as the image
being verified in REPOSITORY_A (see the verify-reproducibility
pipeline, ADR-0069).


## Parameters
|name|description|default value|required|
|---|---|---|---|
|REPOSITORY_A|First repository to compare.||true|
|REPOSITORY_B|Second repository to compare.||true|


## Additional info
