## Deprecation notice

This task is deprecated, please remove it from your pipeline.
Deprecation date: 2025-01-31

# Migration from 0.1 to 0.2

Version 0.2:

No changes within this version, its only purpose is to provide information on how to remove this task from your pipeline.

## Action from users

To remove this task from your pipeline please follow these steps:

1. Remove the inspect-image task definition from your FBC pipelines similar to this change:

```diff
--- a/.tekton/original-pipelinerun.yaml
+++ b/.tekton/new-pipelinerun.yaml
@@ -271,31 +271,6 @@ spec:
         - name: kind
           value: task
         resolver: bundles
-    - name: inspect-image
-      params:
-      - name: IMAGE_URL
-        value: $(tasks.build-image-index.results.IMAGE_URL)
-      - name: IMAGE_DIGEST
-        value: $(tasks.build-image-index.results.IMAGE_DIGEST)
-      runAfter:
-      - build-image-index
-      taskRef:
-        params:
-        - name: name
-          value: inspect-image
-        - name: bundle
-          value: quay.io/konflux-ci/tekton-catalog/task-inspect-image:0.1@sha256:c8d7616fba1533637547eccd598314721a106ec0d108dcb5162e234d5d90c755
-        - name: kind
-          value: task
-        resolver: bundles
-      when:
-      - input: $(params.skip-checks)
-        operator: in
-        values:
-        - "false"
-      workspaces:
-      - name: source
-        workspace: workspace
     - name: fbc-validate
       params:
       - name: IMAGE_URL
@@ -302,10 +302,8 @@ spec:
         value: $(tasks.build-image-index.results.IMAGE_URL)
       - name: IMAGE_DIGEST
         value: $(tasks.build-image-index.results.IMAGE_DIGEST)
-      - name: BASE_IMAGE
-        value: $(tasks.inspect-image.results.BASE_IMAGE)
       runAfter:
-      - inspect-image
+      - build-image-index
       taskRef:
         params:
         - name: name
```
