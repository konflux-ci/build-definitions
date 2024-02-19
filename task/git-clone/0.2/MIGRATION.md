# Migration from 0.1 to 0.2

- The parameter `deleteExisting` used by `git-clone` task was removed. As the
  source is no longer maintained in the workspace, all executions of the
  `git-clone` Task will be clean fetches.
- The parameter `subdirectory` used by `git-clone` task was removed.
- The `output` workspace will not contain any source files, only the trusted
  artifact containing the source files, to access the source files use the
  trusted artifacts[^1]

## Action from users

Update files in pull request created by RHTAP bot:
- Search for the task named `git-clone`
- Remove the `deleteExisting` and `subdirectory` parameters from the `params`
  section

Any Tasks that require the source code now need be provided with the trusted
artifact URI from the result of the `git-clone` Task and include a step similar
to:

```yaml
params:
  # used to pass in the SOURCE_ARTIFACT result from the git-clone Task
  - name: SOURCE_ARTIFACT
    type: string
    description: The source trusted artifact URI
    default: ""

steps:
  - name: use-trusted-artifact
    image: quay.io/redhat-appstudio/build-trusted-artifacts:latest@sha256:96eb85645cc62e7041fbeb36fc71ed313a45c239903f52542bfed2ceeaf58e4a
    args:
      - use
      - --store
      - $(workspaces.source.path) # references the same workspace provided to the git-clone task
      - $(params.SOURCE_ARTIFACT)=/var/source # adjust the destination (/var/source) as needed
```

And the `SOURCE_ARTIFACT` parameter needs to be passed via the Pipeline from the
`git-clone` Task with the same name. For example:

```yaml
tasks:
  - name: my-task
    params:
      - name: SOURCE_ARTIFACT
        value: $(tasks.clone-repository.results.SOURCE_ARTIFACT) # clone-repository is the name of the git-clone Task in the Pipeline
```

[^1]: https://github.com/redhat-appstudio/build-trusted-artifacts
