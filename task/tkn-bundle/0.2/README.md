# tkn-bundle task

Creates and pushes a Tekton bundle containing the specified Tekton YAML files.

## Parameters
|name|description|default value|required|
|---|---|---|---|
|IMAGE|Reference of the image task will produce.||true|
|CONTEXT|Path to the directory to use as context.|.|false|
|HOME|Value for the HOME environment variable.|/tekton/home|false|
|STEPS_IMAGE|An optional image to configure task steps with in the bundle|""|false|
|URL|Source code Git URL||true|
|REVISION|Revision||true|

## Results
|name|description|
|---|---|
|IMAGE_DIGEST|Digest of the image just built|
|IMAGE_URL|Image repository and tag where the built image was pushed with tag only|
|IMAGE_REF|Image reference of the built image|

## Workspaces
|name|description|optional|
|---|---|---|
|source||false|

## Additional info

`CONTEXT` can include multiple directories or files separated by comma or space.
Paths can be negated with exclamation mark to prevent inclusion of certain
directories or files. Negated paths are best placed at the end as they operate
on collected paths preceeding them. For example if `CONTEXT` is set to
`"0.1,!0.1/spec"` for this tree:

    .
    ├── 0.1
    │   ├── README.md
    │   ├── spec
    │   │   ├── spec_helper.sh
    │   │   ├── support
    │   │   │   ├── jq_matcher.sh
    │   │   │   └── task_run_subject.sh
    │   │   ├── test1.yaml
    │   │   ├── test2.yml
    │   │   ├── test3.yaml
    │   │   └── tkn-bundle_spec.sh
    │   ├── TESTING.md
    │   └── tkn-bundle.yaml
    └── OWNERS

Only the `0.1/tkn-bundle.yaml` file will be included in the bundle.

---

Tekton Task to build and push Tekton Bundles (OCI images) which contain
definitions of Tekton objects, most commonly Task and Pipeline objects.

Task finds all `*.yaml` or `*.yml` files within `CONTEXT`, packages and pushes
them as a Tekton Bundle to the image repository, name and tag specified by the
`IMAGE` parameter.

In case a `kustomization.yaml` file is located in `CONTEXT`, it will be used to
generate the task definition and all other files in `CONTEXT` will be ignored.

The task also adds annotations to the Tekton bundle.
