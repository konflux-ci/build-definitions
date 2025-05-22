# Migration from 0.2 to 0.3

Workspace used by the `deprecated-image-check` is removed. This is not required as it doesn't need any PVCs.

## Action from users

Update files in Pull-Request created by RHTAP bot:
- Search for the task named `deprecated-base-image-check`
- Remove the workspaces section from the task
- Do NOT remove workspaces from the other tasks

Example how the section should look like:

BEFORE:
```yaml
  - name: deprecated-base-image-check
    params:
    - name: BASE_IMAGES_DIGESTS
      value: $(tasks.build-container.results.BASE_IMAGES_DIGESTS)
    taskRef:
       params:
       - name: name
         value: deprecated-image-check
     #
     # ...
     #
     when:
     - input: $(params.skip-checks)
       operator: in
       values:
       - "false"
     workspaces:             # <-- remove this
     - name: test-ws         # <-- remove this
       workspace: workspace  # <-- remove this
```

AFTER:
```yaml
  - name: deprecated-base-image-check
    params:
    - name: BASE_IMAGES_DIGESTS
      value: $(tasks.build-container.results.BASE_IMAGES_DIGESTS)
    taskRef:
       params:
       - name: name
         value: deprecated-image-check
     #
     # ...
     #
     when:
     - input: $(params.skip-checks)
       operator: in
       values:
       - "false"
```