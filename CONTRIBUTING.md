# Contributing to build-definitions

## Table of Contents

* [Project Overview](#project-overview)
* [How to Report Issues](#how-to-report-issues)
* [How to Submit Pull Requests](#how-to-submit-pull-requests)
  * [Development Workflow](#development-workflow)
  * [Pull Request Guidelines](#pull-request-guidelines)
  * [Security Best Practices](#security-best-practices)

* [Review Process](#review-process)

## Project Overview

This repository serves as a central repository for several components used in [Konflux](https://konflux-ci.dev).
Therefore, everybody should follow its [Code of Conduct](https://github.com/konflux-ci/community/blob/main/CODE_OF_CONDUCT.md).

This central repository contains components managed by the Konflux Build Team and other various contributors.
See the CODEOWNERS file for more information.

Components are delivered to Konflux via the `konflux-ci/tekton-catalog` Quay organization as OCI bundles.
See the [init-task](https://quay.io/repository/konflux-ci/tekton-catalog/task-init) as an example.

## How to Report Issues

- We encourage early communication for all types of contributions.
- Before filing an issue, make sure to check if it is not reported already.
- If the contribution is non-trivial (straightforward bugfixes, typos, etc.), please open an issue to discuss your plans and get guidance from maintainers.
- Please fill out included issue templates with all applicable information.

## How to Submit Pull Requests

### Development Workflow

1. **Fork and Clone**: Fork this repository and clone your fork
2. **Create Feature Branch**: Create a new topic branch based on `main`
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
- Sign-off your commits in order to certify that you adhere to [Developer Certificate of Origin](https://developercertificate.org)

**Pull Request Content:**
- **Title**: Clear, descriptive title. Should fit under 72 characters.
- **Description**: Explain the overall changes and their purpose, this should be a cover letter for your commits.
- **Testing**: Describe how the changes were tested
- **Links**: Reference related issues or upstream stories.

**Remember:**
- Konflux is a community project and proper descriptions cannot be replaced by referencing a publicly inaccessible link to Jira or any other private resource.
- Reviewers, other contributors and future generations might not have the same context as you have at the moment of PR submission.

### Security Best Practices

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
