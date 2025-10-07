# Migration from 0.5 to 0.6

Version 0.6:

* Introduces **Contextual SBOM feature** for SPDX SBOM format. Contextual SBOM is a
  feature that establishes relationships between container images and their parent
  (base) or builder images in the software supply chain. Instead of treating each
  image as isolated, it creates a hierarchical view showing how packages flow from
  parent or builder images to child images.


* Feature will be released gradually. Planned features:
    * ✅ **Contextual SBOM for non-hermetic build**
        * identification of the base image content in component in non-hermetic build
        * achieved by matching packages from the base image SBOM to the component
          SBOM and marking their origin with relationships
    * ⏳ **Builder content contextualization**
        * identification of the content copied from multistage build stages to component
        * acquired by generating an SBOM from content copied from builder images
          and merged into the final SBOM to indicate the origin of that content
    * ⏳ **Contextual SBOM for hermetic build**
        * differentiation of the base image content and component content in hermetic build
        * assembled from base image content, hermeto content and - in multistage builds -
          builder content


* More info about functionality can be found in
  [mobster documentation](https://github.com/konflux-ci/mobster/blob/main/docs/sboms/oci_image.md)

## Action from users
No specific migration action required. After fulfilling requirements contextual
SBOM will be produced by default.

In case you encounter any issues caused by contextualization, you can set the
CONTEXTUALIZE_SBOM parameter to false. In that case, a legacy SBOM (not contextualized)
will be produced.


## Requirements for executing Contextual SBOM workflow
* Base image of the component must be built by konflux and must have SBOM attached
* Attached base image SBOM must be in SPDX format

If requirements are not fulfilled, legacy SBOM (not contextualized) will be produced.
