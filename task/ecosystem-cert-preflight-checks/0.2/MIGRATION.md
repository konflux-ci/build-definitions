# Migration from 0.1 to 0.2

New optional parameters `artifact-type` and `additional-bundle-validate-args`
can be explicitly set for operator bundle use cases.

## Action from users

### Parameters

No **required** action for users.

Optionally, users may choose to explicitly set `artifact-type` to a predefned
value if they wish to explicitly control the type of artifact (e.g. application
image, or operator bundle image). Otherwise, this is introspected for you.

For operator bundles, users may optionally set the
`additional-bundle-validate-args` values to have finer control over the bundle
validation process. Otherwise, this is set to sane defaults.
