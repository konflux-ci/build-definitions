# apply-tags task

Apply-tags task will apply additional tags to the specified IMAGE. These additional tags can be provided via the ADDITIONAL_TAGS array parameter or they can also be provided in the image label "konflux.additional-tags". If you specify more than one additional tag in the label, they must be separated by a comma or a blank space, e.g:

```
LABEL konflux.additional-tags="tag1, tag2"
```
```
LABEL konflux.additional-tags="tag tag2"
```

## Parameters
|name|description|default value|required|
|---|---|---|---|
|IMAGE|Reference of image that was pushed to registry in the buildah task.||true|
|ADDITIONAL_TAGS|Additional tags that will be applied to the image in the registry.|[]|false|
