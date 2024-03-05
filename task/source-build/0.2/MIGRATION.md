# Migration from 0.1 to 0.2

Apply the following diff to task `build-source-image` inside PipelineRun YAML created by Konflux Bot:

```diff
         - input: $(tasks.init.results.build)
           operator: in
           values: ["true"]
-        - input: $(params.build-source-image)
-          operator: in
-          values: ["true"]
       runAfter:
         - build-container
       taskRef:
@@ -131,6 +128,8 @@ spec:
           value: "$(params.output-image)"
         - name: BASE_IMAGES
           value: "$(tasks.build-container.results.BASE_IMAGES_DIGESTS)"
+        - name: BUILD_SOURCE_IMAGE
+          value: "$(params.build-source-image)"
       workspaces:
         - name: workspace
           workspace: workspace
```
