# Changelog

## 0.2.3

- Added `symlinkCheckIgnorePattern` parameter to exclude symlink paths from the checkout symlink check [konflux-build-cli#132](https://github.com/konflux-ci/konflux-build-cli/pull/132)

## 0.2.2

- Fix SSH setup failing when mounted secrets contain symlinks to directories [konflux-build-cli#165](https://github.com/konflux-ci/konflux-build-cli/pull/165)

## 0.2.1

- `refspec` parameter should now accept multiple refspecs separated by whitespace like in git-clone 0.1 [konflux-build-cli#155](https://github.com/konflux-ci/konflux-build-cli/issues/155)
- Fix handling of whitespaces in gitconfig which should fix most of the issues with basic-auth [konflux-build-cli#159](https://github.com/konflux-ci/konflux-build-cli/pull/159)

## 0.2

- Updated base task to git-clone-oci-ta 0.2.
- Removed `gitInitImage` (deprecated since 0.1), `verbose` (replaced by `logLevel`), and `userHome` (handled by konflux-build-cli) parameters.
- Added `logLevel` parameter.
