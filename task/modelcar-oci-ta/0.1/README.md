# modelcar-oci-ta task

Given a base image and a OCI artifact reference with the model files, builds a ModelCar image.

A ModelCar is a containerized approach to deploying machine learning models. It involves packaging
model artifacts within a container image, enabling efficient and standardized deployment in
Kubernetes environments, used as Sidecar containers (secondary containers that run alongside the
main application container within the same Pod)

The ModelCar image is built using the specified BASE_IMAGE parameter, which is extracted to an
OCI image layout directory. Then all files included in the OCI artifact specified with the
MODEL_IMAGE parameter are copied on top.

An SBOM report defining the Model and Base Images as descendants of the ModelCar image is also
generated in the process.

## Parameters
|name|description|default value|required|
|---|---|---|---|
|MODEL_IMAGE_AUTH|Name of secret required to pull the model OCI artifact||true|
|IMAGE|Reference of the image we will push||true|
|SBOM_TYPE|Select the SBOM format to generate. Valid values: spdx, cyclonedx.|spdx|false|
|SOURCE_ARTIFACT|The Trusted Artifact URI pointing to the artifact with the application source code.||true|
|BASE_IMAGE|base image used to build the Modelcar image||true|
|MODEL_IMAGE|OCI artifact reference with the model files||true|
|MODELCARD_PATH|path to the Model Card||true|
|REMOVE_ORIGINALS|add --remove-originals param to olot|false|false|

## Results
|name|description|
|---|---|
|IMAGE_DIGEST|Digest of the artifact just pushed|
|IMAGE_REF|Image reference of the built image|
|IMAGE_URL|Repository where the artifact was pushed|
|SBOM_BLOB_URL|Link to the SBOM blob pushed to the registry.|


## Additional info
