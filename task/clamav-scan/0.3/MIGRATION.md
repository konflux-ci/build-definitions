# Migration from 0.2 to 0.3

Version 0.3:

On this version clamscan is replaced by clamdscan which can scan an image in parallel (8 threads by default).
Besides that, if the pipelinerun uses a matrix configuration for the task, each arch will create a separate TaskRun, running in parallel.

Changes:
- The `image-arch` parameter definition is added and the defaul value is "".
- The `clamd-max-threads` parameter definition is added and the default is 8.

## Action from users

Renovate bot PR will be created with warning icon for a clamav-scan which is expected, no actions from users are required for the task.

If you have a multi-arch build and the matrix is not yet configured in your PipelineRun, consider adding it to enable concurrent scanning across architectures and improve overall performance, e.g:

```diff
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
     ...
     taskRef:
       params:
       - name: name
         value: clamav-scan
       - name: bundle
-        value: quay.io/konflux-ci/tekton-catalog/task-clamav-scan:0.2@sha256:98d94290d6f21b6e231485326e3629bbcdec75c737b84e05ac9eac78f9a2c8b4
+        value: quay.io/konflux-ci/tekton-catalog/task-clamav-scan:0.3@<digest>
```

Note: To use matrixed scanning, you must use clamav-scan task version >= 0.3.
You can get the correct digest from quay.io/konflux-ci/tekton-catalog/task-clamav-scan and append it after :0.3@.
