# Migration from 0.1 to 0.2

The workspace and parameters are no longer needed for this task.  They were in fact not needed in the 0.1 version already.

## Action from users

No action is needed.  Passing of the unused workspace (and parameters) for this task can optionally be removed like this:
```diff
--- a/.tekton/konflux-test-operator-pipelines-pull-request.yaml
+++ b/.tekton/konflux-test-operator-pipelines-pull-request.yaml
@@ -448,32 +448,24 @@ spec:
       workspaces:
       - name: workspace
         workspace: workspace
     - name: coverity-availability-check
-      params:
-      - name: image-digest
-        value: $(tasks.build-image-index.results.IMAGE_DIGEST)
-      - name: image-url
-        value: $(tasks.build-image-index.results.IMAGE_URL)
       runAfter:
       - build-image-index
       taskRef:
         params:
         - name: name
           value: coverity-availability-check
         - name: bundle
-          value: quay.io/konflux-ci/tekton-catalog/task-coverity-availability-check:0.1
+          value: quay.io/konflux-ci/tekton-catalog/task-coverity-availability-check:0.2
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
     - name: sast-shell-check
       params:
       - name: image-digest
         value: $(tasks.build-image-index.results.IMAGE_DIGEST)
```
