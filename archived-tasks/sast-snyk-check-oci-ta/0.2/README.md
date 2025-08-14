# sast-snyk-check-oci-ta task

Scans source code for security vulnerabilities, including common issues such as SQL injection, cross-site scripting (XSS), and code injection attacks using Snyk Code, a Static Application Security Testing (SAST) tool.

Follow the steps given [here](https://redhat-appstudio.github.io/docs.appstudio.io/Documentation/main/how-to-guides/testing_applications/enable_snyk_check_for_a_product/) to obtain a snyk-token and to enable the snyk task in a Pipeline.

The snyk binary used in this Task comes from a container image defined in https://github.com/konflux-ci/konflux-test

See https://snyk.io/product/snyk-code/ and https://snyk.io/ for more information about the snyk tool.

## Parameters
|name|description|default value|required|
|---|---|---|---|
|ARGS|Append arguments.|--all-projects --exclude=test*,vendor,deps|false|
|CACHI2_ARTIFACT|The Trusted Artifact URI pointing to the artifact with the prefetched dependencies.|""|false|
|SNYK_SECRET|Name of secret which contains Snyk token.|snyk-secret|false|
|SOURCE_ARTIFACT|The Trusted Artifact URI pointing to the artifact with the application source code.||true|
|image-digest|Image digest to report findings for.|""|false|
|image-url|Image URL.|""|false|

## Results
|name|description|
|---|---|
|TEST_OUTPUT|Tekton task test output.|

