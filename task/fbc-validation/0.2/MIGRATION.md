## Deprecation notice

This task is deprecated, please remove it from your pipeline and replace it with the new validate-fbc task.
Deprecation date: 2025-01-31

# Migration from 0.1 to 0.2

Version 0.2:

No changes within this version, its only purpose is to provide information on how to remove this task from your pipeline.

## Action from users

To remove this task from your pipeline please follow these steps:

1. Remove the fbc-validation task definition from your FBC pipelines similar to this change:

```diff
--- a/.tekton/original-pipelinerun.yaml
+++ b/.tekton/new-pipelinerun.yaml
@@ -323,26 +323,6 @@ spec:
       workspaces:
       - name: workspace
         workspace: workspace
-    - name: fbc-validation
+    - name: validate-fbc
-      runAfter:
-      - inspect-image
+      - build-image-index
      taskRef:
        params:
        - name: name
-          value: fbc-validation
+          value: validate-fbc
        - name: bundle
-          value: quay.io/konflux-ci/tekton-catalog/task-fbc-validation:0.1
+          value: quay.io/konflux-ci/tekton-catalog/task-validate-fbc:0.1
        - name: kind
          value: task
        resolver: bundles
      when:
      - input: $(params.skip-checks)
        operator: in
        values:
        - "false"
-      workspaces:
-      - name: workspace
-        workspace: workspace
     workspaces:
     - name: workspace
     - name: git-auth
```
