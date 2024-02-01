# Migration from 0.1 to 0.2

New parameter `hermetic` controls if prefetching of dependencies will be
performed. Set to `true` to perform prefetching.

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
