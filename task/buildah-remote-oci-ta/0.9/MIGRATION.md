# Migration from 0.8 to 0.9

Support for Dockerfile downloading in Konflux Build Pipeline is removed.

## Action from users

If your builds download Dockerfile from an url,
commit the Dockerfile into your source repository
and provide the Dockerfile path (relative to the git repository root) in `dockerfile` parameter.
