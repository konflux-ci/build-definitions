# Migration from 0.2 to 0.3

Version 0.3:

On this version clamscan is replaced by clamdscan which can scan an image in parallel (8 threads by default).
Besides that, if the pipelinerun uses a matrix configuration for the task, each arch will create a separate TaskRun, running in parallel.

Changes:
- The `image-arch` parameter definition is added and the defaul value is "".
- The `clamd-max-threads` parameter definition is added and the default is 8.

## Action from users

Renovate bot PR will be created with warning icon for a clamav-scan which is expected, no actions from users are required for the task.

If the matrix is not yet configured in your PipelineRun, consider adding it to enable concurrent scanning across architectures and improve overall performance.

```diff
@@ -311,7 +311,12 @@ spec:
       values:
       - "false"
     workspaces: []
-  - name: clamav-scan
+  - matrix:
+      params:
+      - name: image-arch
+        value:
+        - $(params.build-platforms)
+    name: clamav-scan
     params:
     - name: image-digest
       value: $(tasks.build-image-index.results.IMAGE_DIGEST)
@@ -321,7 +326,7 @@ spec:
     - build-image-index
     taskRef:
       name: clamav-scan
-      version: "0.2"
+      version: "0.3"
```
