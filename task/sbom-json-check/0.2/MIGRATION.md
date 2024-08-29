## Deprecation notice

This task is deprecated, please remove it from your pipeline.
Deprecation date: 2024-09-30

# Migration from 0.1 to 0.2

Version 0.2:

No changes within this version, its only purpose is to provide information on how to remove this task from your pipeline.

## Action from users

To remove this task from your pipeline please follow these steps:

1. Remove sbom-json-check definition from pipelines/template-build/template-build.yaml

```diff
--- a/pipelines/template-build/template-build.yaml
+++ b/pipelines/template-build/template-build.yaml
@@ -242,21 +242,6 @@ spec:
         value: $(tasks.build-image-index.results.IMAGE_DIGEST)
       - name: image-url
         value: $(tasks.build-image-index.results.IMAGE_URL)
-    - name: sbom-json-check
-      when:
-      - input: $(params.skip-checks)
-        operator: in
-        values: ["false"]
-      runAfter:
-        - build-image-index
-      taskRef:
-        name: sbom-json-check
-        version: "0.1"
-      params:
-      - name: IMAGE_URL
-        value: $(tasks.build-image-index.results.IMAGE_URL)
-      - name: IMAGE_DIGEST
-        value: $(tasks.build-image-index.results.IMAGE_DIGEST)
     - name: apply-tags
       runAfter:
         - build-image-index
```
