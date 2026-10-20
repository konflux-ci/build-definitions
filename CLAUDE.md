- Use additional rules from:
  - @.cursor/rules/basic.mdc
  - @.cursor/rules/git.mdc
  - @.cursor/rules/tekton.mdc

## Repository migration status

Task implementations in this repo are being migrated to
[konflux-ci/tools](https://github.com/konflux-ci/tools) (task logic)
and [konflux-ci/tekton-tools](https://github.com/konflux-ci/tekton-tools)
(task definitions). New changes should target those repos. Tasks here
with `build.appstudio.redhat.com/expires-on` annotations are deprecated.
See `.cursor/rules/tekton.mdc` for details.
