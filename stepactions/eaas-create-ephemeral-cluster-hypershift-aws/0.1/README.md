# eaas-create-ephemeral-cluster-hypershift-aws stepaction

This StepAction provisions an ephemeral cluster using Hypershift with 3 worker nodes in AWS. It does so by creating a ClusterTemplateInstance in a space on an EaaS cluster.

## Parameters
|name|description|default value|required|
|---|---|---|---|
|eaasSpaceSecretRef|Name of a secret containing credentials for accessing an EaaS space.||true|
|version|The version of OpenShift to install. Container images will be pulled from: `quay.io/openshift-release-dev/ocp-release:${version}-multi`.||true|
|instanceType|AWS EC2 instance type for worker nodes. Supported values: `m5.large`, `m5.xlarge`, `m5.2xlarge`, `m6g.large`, `m6g.xlarge`, `m6g.2xlarge`|m6g.large|false|
|insecureSkipTLSVerify|Skip TLS verification when accessing the EaaS hub cluster. This should not be set to "true" in a production environment.|false|false|
|timeout|How long to wait for cluster provisioning to complete.|30m|false|
|imageContentSources|Alternate registry information containing a list of sources and their mirrors in yaml format. See: https://hypershift-docs.netlify.app/how-to/disconnected/image-content-sources|""|false|
|fips| Flag for hypershift cluster creation command to enable/disable FIPS for the cluster.| false| false

## Results
|name|description|
|---|---|
|clusterName|The name of the generated ClusterTemplateInstance resource.|

