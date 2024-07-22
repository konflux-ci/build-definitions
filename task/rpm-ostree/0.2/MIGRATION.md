# Migration from 0.1 to 0.2

Version 0.2:

* Removes the `BASE_IMAGES_DIGESTS` result. Please remove all the references to this
  result from your pipeline.
  * Note that the result never provided any value. It did not contain base image
    digests, it contained a local-only reference for the **output** image
    (`localhost/rhtap-final-image@sha256:...`). The task returns a usable reference
    for the output image as well (`IMAGE_URL` + `IMAGE_DIGEST`).

## Konflux-specific

In a typical Konflux pipeline, the two tasks that used to depend on the `BASE_IMAGES_DIGESTS`
result are `build-source-image` and `deprecated-base-image-check`.

1. Make sure your version of `deprecated-base-image-check` is at least `0.4`.
2. Remove the parameters that reference the `BASE_IMAGES_DIGESTS` result:

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
