# apply-tags task

Apply-tags task will apply additional tags to the specified IMAGE. These additional tags can be provided via the ADDITIONAL_TAGS array parameter or they can also be provided in the image label "konflux.additional-tags". If you specify more than one additional tag in the label, they must be separated by a comma or a blank space, e.g:

```
LABEL konflux.additional-tags="tag1, tag2"
```
```
LABEL konflux.additional-tags="tag tag2"
```

## Parameters
| name                     | description                                                            | default value | required |
|--------------------------|------------------------------------------------------------------------|---------------|----------|
| IMAGE_URL                | Image repository and tag reference of the the built image.             |               | true     |
| IMAGE_DIGEST             | Image digest of the built image.                                       |               | true     |
| ADDITIONAL_TAGS          | Additional tags that will be applied to the image in the registry.     | []            | false    |
| CA_TRUST_CONFIG_MAP_NAME | The name of the ConfigMap to read CA bundle data from.                 | trusted-ca    | false    |
| CA_TRUST_CONFIG_MAP_KEY  | The name of the key in the ConfigMap that contains the CA bundle data. | ca-bundle.crt | false    |
