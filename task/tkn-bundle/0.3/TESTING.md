# Testing tkn-bundle Tekton Task

Make sure you have shellspec installed[1]. The test setup script will bring up a
kind[2] cluster and installs Tekton Pipeline. The source is provided via the
`source-pvc` PersistantVolumeClaim and prepopulated with the test?.y*ml files in
order to not necesate the need for source checkout.

For second and subsequent invocations the setup is quicker as it only applies
any changes to already started and setup cluster. To delete the cluster and
start afresh run: `kind delete cluster --name=test-tkn-bundle`.

To run the tests run `shellspec` from this directory.

## Test coverage

In addition to the tests from 0.1 (context handling, negation, HOME override),
this version adds tests for the `STEPS_IMAGE_STEP_NAMES` parameter:

- Replacing all step images (STEPS_IMAGE set, STEPS_IMAGE_STEP_NAMES empty)
- Replacing a single named step image
- Replacing multiple named step images (comma-separated)
- No replacement when step name doesn't match any steps

The `test1.yaml` fixture has two steps (`build` with `ubuntu`, `test` with
`alpine`) to verify selective replacement leaves unmatched steps unchanged.

## Example of a testing setup and session

```shell
$ pwd
.../build-definitions/task/tkn-bundle/0.3
$ shellspec --jobs 5
Running: /bin/sh [bash 5.2.15(1)-release]
namespace/tekton-pipelines created
clusterrole.rbac.authorization.k8s.io/tekton-pipelines-controller-cluster-access created
...
pod "setup-1674815473" deleted
deployment.apps/registry created
service/registry created
deployment.apps/registry condition met
deployment.apps/tekton-pipelines-controller condition met
deployment.apps/tekton-pipelines-webhook condition met
..........

Finished in 180.00 seconds (user 7.37 seconds, sys 4.03 seconds)
10 examples, 0 failures
```

[1] https://shellspec.info/
[2] https://kind.sigs.k8s.io/
