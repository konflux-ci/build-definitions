# Migration from 0.1 to 0.2

Starting with version 0.2, the `coverity-availability-check-oci-ta` task is deprecated.  Please use `coverity-availability-check` instead.

## Action from users

In your pipelines, find the references to `coverity-availability-check-oci-ta` and replace them with `coverity-availability-check`.
For the task bundle (the `quay.io/...` reference), you will also need to change the sha256 digest. Example:

```diff
       taskRef:
         resolver: bundles
         params:
         - name: name
-          value: coverity-availability-check-oci-ta
+          value: coverity-availability-check
         - name: bundle
-          value: quay.io/konflux-ci/tekton-catalog/task-coverity-availability-check-oci-ta:0.2@sha256:8653d290298593e4db9457ab00d9160738c31c384b7615ee30626ccab6f96ed8
+          value: quay.io/konflux-ci/tekton-catalog/task-coverity-availability-check:0.2@sha256:91ba738df7ec548d4127163e07a88de06568a350fbf581405cc8fc8498f6153c
         - name: kind
           value: task
```

If you would prefer to use the latest digest rather than the one which was latest at the time of writing this doc, get it with:

```bash
skopeo inspect --no-tags --format '{{.Digest}}' docker://quay.io/konflux-ci/tekton-catalog/task-coverity-availability-check:0.2
```
