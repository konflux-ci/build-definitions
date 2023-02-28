# label-check task

## Description:
The label-check task utilizes Conftest to verify label data. Conftest is an open-source tool that provides a way
to enforce policies written in a high-level declarative language called Rego.

# Params:

| name             | description                                     |
|------------------|-------------------------------------------------|
| POLICY_DIR       | Path to directory containing Conftest policies. |
| POLICY_NAMESPACE | Conftest policy namespace.                      |

## Results:

| name                  | description              |
|-----------------------|--------------------------|
| HACBS_TEST_OUTPUT     | Tekton task test output. |

## Source repository for image:
https://github.com/redhat-appstudio/hacbs-test

## Additional links:
https://github.com/open-policy-agent/conftest