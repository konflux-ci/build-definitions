# Migration from 0.1 to 0.2

Version 0.2:

* Removes the `BASE_IMAGES_DIGESTS` result. Please remove all the references to this
  result from your pipeline.
  * Base images and their digests can be found in the SBOM for the output image.
* No longer writes the `base_images_from_dockerfile` file into the `source` workspace.
* Removes the `BUILDER_IMAGE` and `DOCKER_AUTH` params. Neither one did anything
  in the later releases of version 0.1. Please stop passing these params to the
  buildah task if you used to do so with version 0.1.

## Konflux-specific

In a typical Konflux pipeline, the two tasks that used to depend on the `BASE_IMAGES_DIGESTS`
result are `build-source-image` and `deprecated-base-image-check`.

1. Make sure your version of `deprecated-base-image-check` is at least `0.4`.
2. Make sure your version of `build-source-image` supports reading base images from
   the SBOM. Version `0.1` supports it since 2024-07-15. In the logs of your build
   pipeline, you should see that the build-source-image task now has a GET-BASE-IMAGES
   step. Once you stop passing the `BASE_IMAGES_DIGESTS` param, this step will emit
   logs about handling the SBOM.
3. Remove the parameters that reference the `BASE_IMAGES_DIGESTS` result:

```diff
@@ -255,10 +255,8 @@ spec:
     - name: build-source-image
       params:
       - name: BINARY_IMAGE
         value: $(params.output-image)
-      - name: BASE_IMAGES
-        value: $(tasks.build-container.results.BASE_IMAGES_DIGESTS)
       runAfter:
       - build-container
       taskRef:
         params:
@@ -282,10 +280,8 @@ spec:
       - name: workspace
         workspace: workspace
     - name: deprecated-base-image-check
       params:
-      - name: BASE_IMAGES_DIGESTS
-        value: $(tasks.build-container.results.BASE_IMAGES_DIGESTS)
       - name: IMAGE_URL
         value: $(tasks.build-container.results.IMAGE_URL)
       - name: IMAGE_DIGEST
         value: $(tasks.build-container.results.IMAGE_DIGEST)
```
