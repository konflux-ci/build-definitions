# Contributing to build-definitions

## Table of Contents

* [Project Overview](#project-overview)
* [How to Report Issues](#how-to-report-issues)
  * [Bug Reports](#bug-reports)
  * [Feature Requests](#feature-requests)
* [How to Submit Pull Requests](#how-to-submit-pull-requests)
  * [Development Workflow](#development-workflow)
  * [Pull Request Guidelines](#pull-request-guidelines)
  * [Code Quality Standards](#code-quality-standards)
  * [Security Best Practices](#security-best-practices)
* [Contribution Types](#contribution-types)
  * [Adding New Tasks](#adding-new-tasks)
  * [Modifying Existing Tasks](#modifying-existing-tasks)
  * [Adding New Pipelines](#adding-new-pipelines)
  * [Adding External Tasks](#adding-external-tasks)
  * [Task Deprecation](#task-deprecation)
* [Review Process](#review-process)

## Project Overview

This repository serves as a central repository for several components used in [Konflux](https://konflux-ci.dev).
Therefore, everybody should follow its [Code of Conduct](https://github.com/konflux-ci/community/blob/main/CODE_OF_CONDUCT.md).

This central repository contains components managed by the Konflux Build Team and other various contributors.
See the CODEOWNERS file for more information.

Components are delivered to Konflux via the `konflux-ci/tekton-catalog` Quay organization as OCI bundles.

## How to Report Issues

We encourage early communication for all types of contributions.
If the contribution is non-trivial (straightforward bugfixes, typos, etc.), please open an issue to discuss your plans and get guidance from maintainers.

### Bug Reports

When reporting bugs, please include the following information:

**Required Information:**
- **Problem Description**: Clear, concise description of what went wrong
- **Steps to Reproduce**: Detailed steps to recreate the issue
- **Current Behavior**: What actually happened
- **Expected Behavior**: What you expected to happen
- **Other information**: For example relevant error messages or logs


### Feature Requests

For feature requests, please provide:

- **Use Case**: Describe the problem you're trying to solve
- **Proposed Solution**: Your suggested approach (if any)
- **Alternatives Considered**: Other solutions you've thought about
- **Impact**: Who would benefit from this feature


## How to Submit Pull Requests

### Development Workflow

1. **Fork and Clone**: Fork this repository and clone your fork
2. **Create Feature Branch**: Create a new branch from `main`
3. **Make Changes**: Implement your changes
4. **Generate Content**: Run generation scripts if needed
   ```bash
   ./hack/generate-everything.sh
   ```
6. **Commit Changes**: See [commit guidelines](#pull-request-guidelines)

### Pull Request Guidelines

**Commit Requirements:**
- Write clear, descriptive commit titles. Should fit under 50 characters
- Write meaningful commit descriptions with each line having less than 72 characters
- Split your contribution into several commits if applicable, each should represent a logical chunk
- Add line `Assisted-by: <name-of-ai-tool>` if you used an AI tool for your contribution

**Pull Request Content:**
- **Title**: Clear, descriptive title. Should fit under 72 characters.
- **Description**: Explain the changes and their purpose. You may refer to commit descriptions.
- **Testing**: Describe how the changes were tested
- **Links**: Reference related issues or upstream stories.

**Remember:**
- Konflux is a community project and proper descriptions cannot be replaced by referencing a publicly inaccessible link to Jira or any other private resource.
- Reviewers, other contributors and future generations might not have the same context as you have at the moment of PR submission.

### Code Quality Standards

**Shell Scripts:**
- Set `set -euo pipefail` at the beginning of bash scripts
- Pass shellcheck
- Explain unintuitive code with comments

### Security Best Practices

**Critical Requirements:**
- Never commit secrets or keys to the repository
- Never expose or log sensitive information

## Review Process

**Requirements for Approval:**
- All CI checks pass
- Code review approval from maintainers

**Review Criteria:**
- The contribution follows established patterns and conventions
- Changes are tested and documented
- Breaking changes result in a new version and include migration
- Security best practices are followed

For any questions or help with contributing, please open an issue or reach out to the maintainers.
