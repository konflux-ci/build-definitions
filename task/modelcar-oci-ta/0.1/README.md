# modelcar-oci-ta task

Given a Base Image, and a Model OCI artifact reference, the `modelcar-oci-ta` task will generate a 
Modelcar image.

The build process is done using ORAS (https://github.com/oras-project/oras) and OLOT 
(https://github.com/containers/olot). The process consists on extracting the files from the provided
Model OCI artifact reference, and putting the layers on top of the provided Base Image.

This operation requires about 2 times the size of the model files' size (as opposed to using a tool
like podman or buildah where the requirement is of about 2-3 times the model files size), allowing
to build ModelCar images with lower disk footprint during the build.

Future optimisations might eventually leverage the capability of OLOT to remove each file once
layered on top of the base image, using the [`--remove-originals` feature flag](https://github.com/containers/olot/pull/17). 

The task also generates a limited SBOM and pushes that into the OCI registry alongside the image.

The relationship of the components of the SBOM report is the following:

- There are 3 components reported in the SBOM, the Modelcar image, and the Base and Model images
- The Modelcar component is a descendant of both the Model and the Base images

## Parameters
|name|description|default value|required|
|---|---|---|--|
|IMAGE|Reference of the image we will push||true|
|MODEL_IMAGE|OCI Artifact of the Model image resolved to the digest. ||true|
|BASE_IMAGE|OCI Artifact of the Base image resolved to the digest. |registry.access.redhat.com/ubi9/ubi-micro:9.5@\<digest\>|false|
|SBOM_TYPE|Select the SBOM format to generate. Valid values: spdx, cyclonedx.|spdx|false|

## Results
|name|description|
|---|---|
|IMAGE_DIGEST|Digest of the artifact just pushed|
|IMAGE_URL|Repository where the artifact was pushed|
|SBOM_BLOB_URL|Link to the SBOM blob pushed to the registry.|
|IMAGE_REF|Image reference of the built image|

## Workspaces
|name|description|optional|
|---|---|---|
|source|Workspace containing the source code.|false|
