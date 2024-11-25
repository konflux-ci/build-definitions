# Migration from 0.1 to 0.2

- The workspace has been renamed to `source` to make the interface compatible
  with the `build-container` task.

- The unused `IMAGE_DIGEST` parameter has been removed.

## Action from users

- The workspace for this task in the build pipeline should be renamed to `source`.
- The `IMAGE_DIGEST` parameter definition can optionally be removed for this task in the build pipeline.

### Example
```diff
--- a/.tekton/konflux-test-operator-pipelines-pull-request.yaml
+++ b/.tekton/konflux-test-operator-pipelines-pull-request.yaml
@@ -417,40 +417,38 @@ spec:
       when:
       - input: $(params.skip-checks)
         operator: in
         values:
         - "false"
     - name: sast-coverity-check
       params:
-      - name: image-digest
-        value: $(tasks.build-image-index.results.IMAGE_DIGEST)
       - name: image-url
         value: $(tasks.build-image-index.results.IMAGE_URL)
       runAfter:
       - coverity-availability-check
       taskRef:
         params:
         - name: name
           value: sast-coverity-check
         - name: bundle
-          value: quay.io/konflux-ci/tekton-catalog/task-sast-coverity-check:0.1@sha256:6d0bead975a9e9ce9dac98edb0a3c3908dbae3882df2775fc8760c6bb4f41f8c
+          value: quay.io/konflux-ci/tekton-catalog/task-sast-coverity-check:0.2
         - name: kind
           value: task
         resolver: bundles
       when:
       - input: $(params.skip-checks)
         operator: in
         values:
         - "false"
       - input: $(tasks.coverity-availability-check.results.STATUS)
         operator: in
         values:
         - success
       workspaces:
-      - name: workspace
+      - name: source
         workspace: workspace
     - name: coverity-availability-check
       runAfter:
       - build-image-index
       taskRef:
         params:
         - name: name
```
