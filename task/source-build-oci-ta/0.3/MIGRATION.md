# Migration from 0.2 to 0.3

Version 0.3:

`source-build-oci-ta` task has a new required parameter `BINARY_IMAGE_DIGEST`.
Make these changes to parameters of `build-source-image` task in build pipelines:

* Pass build task result `IMAGE_URL` to parameter `BINARY_IMAGE`.
* Pass build task result `IMAGE_DIGEST` to parameter `BINARY_IMAGE_DIGEST`.

The build task can be either `build-image-index` or `build-container` according
to users build pipeline. If both are included, `build-image-index` takes
precedence.

## Action from users

Apply either of the following diffs to `build-source-image` task in build pipelines:

```diff
       params:
         - name: BINARY_IMAGE
-          value: "$(params.output-image)"
+          value: "$(tasks.build-image-index.results.IMAGE_URL)"
+        - name: BINARY_IMAGE_DIGEST
+          value: "$(tasks.build-image-index.results.IMAGE_DIGEST)"
       workspaces:
```

or

```diff
       params:
         - name: BINARY_IMAGE
-          value: "$(params.output-image)"
+          value: "$(tasks.build-container.results.IMAGE_URL)"
+        - name: BINARY_IMAGE_DIGEST
+          value: "$(tasks.build-container.results.IMAGE_DIGEST)"
       workspaces:
```
