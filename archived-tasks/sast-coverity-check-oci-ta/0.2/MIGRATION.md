# Migration from 0.1 to 0.2

- The workspace has been renamed to `source` to make the interface compatible
  with the `build-container` task.

- The unused `IMAGE_DIGEST` parameter has been removed.

- The `sast-coverity-check` task now supports buildful SAST scanning, too.

## Action from users

- The workspace for this task in the build pipeline should be renamed to `source`.
- All parameters that are set for the `build-container` task now need to be set for `sast-coverity-check-oci-ta`, too.
- The `IMAGE_DIGEST` parameter definition can optionally be removed for this task in the build pipeline.

### Example
```diff
--- a/.tekton/konflux-test-ec-cli-pull-request.yaml
+++ b/.tekton/konflux-test-ec-cli-pull-request.yaml
@@ -260,28 +260,45 @@ spec:
       - input: $(tasks.init.results.build)
         operator: in
         values:
         - "true"
     - name: sast-coverity-check-oci-ta
       params:
-      - name: image-digest
-        value: $(tasks.build-image-index.results.IMAGE_DIGEST)
       - name: image-url
         value: $(tasks.build-image-index.results.IMAGE_URL)
+      - name: IMAGE
+        value: $(params.output-image)
+      - name: DOCKERFILE
+        value: $(params.dockerfile)
+      - name: CONTEXT
+        value: $(params.path-context)
+      - name: HERMETIC
+        value: $(params.hermetic)
+      - name: PREFETCH_INPUT
+        value: $(params.prefetch-input)
+      - name: IMAGE_EXPIRES_AFTER
+        value: $(params.image-expires-after)
+      - name: COMMIT_SHA
+        value: $(tasks.clone-repository.results.commit)
+      - name: BUILD_ARGS
+        value:
+        - $(params.build-args[*])
+      - name: BUILD_ARGS_FILE
+        value: $(params.build-args-file)
       - name: SOURCE_ARTIFACT
         value: $(tasks.prefetch-dependencies.results.SOURCE_ARTIFACT)
       - name: CACHI2_ARTIFACT
         value: $(tasks.prefetch-dependencies.results.CACHI2_ARTIFACT)
       runAfter:
         - coverity-availability-check
       taskRef:
         params:
         - name: name
           value: sast-coverity-check-oci-ta
         - name: bundle
-          value: quay.io/konflux-ci/tekton-catalog/task-sast-coverity-check-oci-ta:0.1
+          value: quay.io/konflux-ci/tekton-catalog/task-sast-coverity-check-oci-ta:0.2
         - name: kind
           value: task
         resolver: bundles
       when:
         - input: $(params.skip-checks)
           operator: in

```
