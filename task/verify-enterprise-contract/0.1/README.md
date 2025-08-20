# verify-enterprise-contract task

Verify the enterprise contract is met

## Parameters
|name|description|default value|required|
|---|---|---|---|
|IMAGES|Spec section of an ApplicationSnapshot resource. Not all fields of the resource are required. A minimal example:  ```json   {     "components": [       {         "containerImage": "quay.io/example/repo:latest"       }     ]   } ```  Each `containerImage` in the `components` array is validated. ||true|
|POLICY_CONFIGURATION|Name of the policy configuration (EnterpriseContractPolicy resource) to use. `namespace/name` or `name` syntax supported. If namespace is omitted the namespace where the task runs is used. You can also specify a policy configuration using a git url, e.g. `github.com/conforma/config//slsa3`. |enterprise-contract-service/default|false|
|PUBLIC_KEY|Public key used to verify signatures. Must be a valid k8s cosign reference, e.g. k8s://my-space/my-secret where my-secret contains the expected cosign.pub attribute.|""|false|
|REKOR_HOST|Rekor host for transparency log lookups|""|false|
|IGNORE_REKOR|Skip Rekor transparency log checks during validation.|false|false|
|TUF_MIRROR|TUF mirror URL. Provide a value when NOT using public sigstore deployment.|""|false|
|SSL_CERT_DIR|Path to a directory containing SSL certs to be used when communicating with external services. This is useful when using the integrated registry and a local instance of Rekor on a development cluster which may use certificates issued by a not-commonly trusted root CA. In such cases, `/var/run/secrets/kubernetes.io/serviceaccount` is a good value. Multiple paths can be provided by using the `:` separator. |""|false|
|CA_TRUST_CONFIGMAP_NAME|The name of the ConfigMap to read CA bundle data from.|trusted-ca|false|
|CA_TRUST_CONFIG_MAP_KEY|The name of the key in the ConfigMap that contains the CA bundle data.|ca-bundle.crt|false|
|INFO|Include rule titles and descriptions in the output. Set to `"false"` to disable it.|true|false|
|STRICT|Fail the task if policy fails. Set to `"false"` to disable it.|true|false|
|HOMEDIR|Value for the HOME environment variable.|/tekton/home|false|
|EFFECTIVE_TIME|Run policy checks with the provided time.|now|false|
|EXTRA_RULE_DATA|Merge additional Rego variables into the policy data. Use syntax "key=value,key2=value2..."|""|false|
|TIMEOUT|This param is deprecated and will be removed in future. Its value is ignored. EC will be run without a timeout. (If you do want to apply a timeout use the Tekton task timeout.) |""|false|
|WORKERS|Number of parallel workers to use for policy evaluation.|1|false|
|SINGLE_COMPONENT|Reduce the Snapshot to only the component whose build caused the Snapshot to be created|false|false|
|SINGLE_COMPONENT_CUSTOM_RESOURCE|Name, including kind, of the Kubernetes resource to query for labels when single component mode is enabled, e.g. pr/somepipeline. |unknown|false|
|SINGLE_COMPONENT_CUSTOM_RESOURCE_NS|Kubernetes namespace where the SINGLE_COMPONENT_NAME is found. Only used when single component mode is enabled. |""|false|

## Results
|name|description|
|---|---|
|TEST_OUTPUT|Short summary of the policy evaluation for each image|

## Workspaces
|name|description|optional|
|---|---|---|
|data|The workspace where the snapshot spec json file resides|true|

## Additional info

This task verifies a signature and attestation for an image and then runs a policy against the image's attestation using the ```ec validate image``` command.

## Install the task
kubectl apply -f https://raw.githubusercontent.com/enterprise-contract/ec-cli/main/tasks/verify-enterprise-contract/0.1/verify-enterprise-contract.yaml


## Usage

This TaskRun runs the Task to verify an image. This assumes a policy is created and stored on the cluster with the namespaced name of `enterprise-contract-service/default`. For more information on creating a policy, refer to the Enterprise Contract [documentation](https://enterprise-contract.github.io/ecc/main/index.html).

```yaml
apiVersion: tekton.dev/v1
kind: TaskRun
metadata:
  name: verify-enterprise-contract
spec:
  taskRef:
    name: verify-enterprise-contract
  params:
  - name: IMAGES
    value: '{"components": ["containerImage": "quay.io/example/repo:latest"]}'
```
