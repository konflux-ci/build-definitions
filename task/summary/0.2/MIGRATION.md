# Migration from 0.1 to 0.2

Apply the following diff to task `show-summary` inside PipelineRun YAML created by Konflux Bot:

```diff
         value: $(params.output-image)
       - name: build-task-status
         value: $(tasks.build-container.status)
+      - name: source-image-url
+        value: "$(tasks.build-source-image.results.SOURCE_IMAGE_URL)"
   results:
     - name: IMAGE_URL
       value: "$(tasks.build-container.results.IMAGE_URL)"
```
