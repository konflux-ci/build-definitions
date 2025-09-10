# Migration from 0.4 to 0.4.1

Version 0.4.1:

* Add the `SOURCE_URL` parameter.

## Action from users
`SOURCE_URL` will be added to build pipeline definition files
automatically by script migrations/0.4.1.sh when MintMaker runs
[pipeline-migration-tool](https://github.com/konflux-ci/pipeline-migration-tool).

To achieve the migration manually, you can do as follows in the build task array:
```diff
     params:
     [...]
+    - name: SOURCE_URL
+      value: $(tasks.clone-repository.results.url)
     [...]
```
