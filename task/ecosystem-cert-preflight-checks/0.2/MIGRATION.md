# Migration from 0.1 to 0.2

New optional parameters `artifact-type` can be explicitly set to control the
application of ecosystem checks on your image.

## Action from users

### Parameters

No **required** action for users.

Optionally, users may choose to explicitly set `artifact-type` to a predefined
value if they wish to explicitly control the type of artifact (e.g. application
image "application", or operator bundle image "operatorbundle"). Otherwise, this
is introspected.
