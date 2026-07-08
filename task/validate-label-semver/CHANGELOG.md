# Changelog

<!-- Format guidelines: https://keepachangelog.com/en/1.1.0/#how -->

## Unreleased

*Nothing yet.*

## 0.1

- Initial release: validates container image version labels against a declared
  semver pattern (VERSION_PATTERN, default `{MAJOR}.{MINOR}.{PATCH}`).
- Fails the build when the version segment count doesn't match the pattern,
  preventing PURL inconsistencies that break downstream CVE scanning.
