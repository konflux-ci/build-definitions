# Migration from 0.1 to 0.2

This version uses the trusted artifacts[^1] and requires that the
`SOURCE_ARTIFACT` parameter contains the URI to the previously created source
artifact, e.g. using the git-clone Task version 0.3 or newer.

As a consequence of using trusted artifacts, it no longer uses workspaces.

## Action from users

Update files in Pull-Request created by RHTAP bot:
- Search for the task named `sast-snyk-check`
- provide the `SOURCE_ARTIFACT` parameter with the value from the result of the
  `git-clone` Task. For example:

```diff
 - name: sast-snyk-check
   params:
+  - name: SOURCE_ARTIFACT
+    value: $(tasks.clone-repository.results.SOURCE_ARTIFACT) # clone-repository is the name of the git-clone Task in the Pipeline
```

Remove the workspace named `workspace`:

```diff
-      workspaces:
-      - name: workspace
-        workspace: workspace
```

[^1]: https://github.com/redhat-appstudio/build-trusted-artifacts
