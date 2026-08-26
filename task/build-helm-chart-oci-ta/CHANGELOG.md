# Changelog

## 0.3.1

### Fixed

Skip adding helm repositories for `file://` protocol dependencies.
Helm cannot register local filesystem paths as remote repositories, causing
`helm repo add` to fail with "could not find protocol handler for: file".
Local dependencies are resolved by `helm dependency build` directly from the
filesystem without requiring a repository entry.
