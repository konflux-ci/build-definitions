# Migration from 0.1 to 0.2

New parameter `hermetic` controls if prefetching of dependencies will be
performed. Set to `true` to perform prefetching.

This version uses the trusted artifacts[^1] and requires that the `SOURCE_ARTIFACT`
parameter contains the URI to the previously created source artifact, e.g. using
the git-clone Task version 0.3 or newer.

Two new results are emitted `SOURCE_ARTIFACT` and `CACHI2_ARTIFACT` containing
the URIs to the modified source and prefetched dependencies trusted artifacts.
Use both with the trusted artifacts[^1] to maintain a hermetic build.

As a consequence of using trusted artifacts, it no longer uses workspaces.

New parameter `OCI_STORAGE` specifies the OCI repository in which the trusted
artifacts created by this task are stored.

New parameter `IMAGE_EXPIRES_AFTER` specifies an expiration for the artifacts
created in the OCI repository.

## Action from users

Update Pipeline definition files in pull request created by RHTAP bot:

- Search for the task named `prefetch-dependencies`
- Remove the `when` section controling the execution of the Task and to the `params` section pass the value of the Pipeline parameter `hermetic` (`$(params.hermetic)`) for the `hermetic` parameter of the Task. For example:

  ```diff
   - name: prefetch-dependencies
  -  when:
  -  - input: $(params.hermetic)
  -    operator: in
  -    values: ["true"]
     params:
     - name: input
       value: $(params.prefetch-input)
  +  - name: hermetic
  +    value: $(params.hermetic)
  ```

Also provide the `SOURCE_ARTIFACT` parameter value from the result of the
`git-clone` Task. For example:

```diff
 - name: prefetch-dependencies
   params:
+  - name: SOURCE_ARTIFACT
+    value: $(tasks.clone-repository.results.SOURCE_ARTIFACT) # clone-repository is the name of the git-clone Task in the Pipeline
```

Add a new parameter named `OCI_STORAGE` with the value of `$(params.output-image)-prefetch`.

Add a new parameter named `IMAGE_EXPIRES_AFTER` with the value of `$(params.image-expires-after)`.
This particular paramater is only needed on pull request pipelines.

Remove the `source` workspace.

[^1]: https://github.com/redhat-appstudio/build-trusted-artifacts
