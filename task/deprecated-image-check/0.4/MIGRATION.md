# Migration from 0.3 to 0.4

New mandatory parameters are required in version 0.4: `IMAGE_URL` and `IMAGE_DIGEST`

Unused result `PYXIS_HTTP_CODE` has been removed in version 0.4.

## Action from users

### New parameters

Update files in Pull-Request created by Konflux bot:

- Search for the task named `deprecated-base-image-check`
- Add the new parameters into yaml files

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
```

AFTER:
```yaml
  - name: deprecated-base-image-check
    params:
    - name: BASE_IMAGES_DIGESTS
      value: $(tasks.build-container.results.BASE_IMAGES_DIGESTS)
    - name: IMAGE_URL
      value: $(tasks.build-container.results.IMAGE_URL)
    - name: IMAGE_DIGEST
      value: $(tasks.build-container.results.IMAGE_DIGEST)
    taskRef:
       params:
       - name: name
         value: deprecated-image-check
```

### Removed result

Update files in Pull-Request created by RHTAP bot:

- Search for the result named `PYXIS_HTTP_CODE` (given the historical reasons 0 occurences may be found)
- Remove all occurences
