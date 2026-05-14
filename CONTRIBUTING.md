# Contributing to Project Imagine

Thanks for your interest in contributing. This document covers the conventions that apply across the organization. Individual repositories may add their own `CONTRIBUTING.md` for project-specific details, which take precedence over this document.

## Before You Start

- Read the [Code of Conduct](./CODE_OF_CONDUCT.md). It applies everywhere in this organization.
- Read the [Governance](./GOVERNANCE.md) document to understand how decisions are made.
- For security issues, **do not open a public issue** — follow the [Security Policy](./SECURITY.md).

## Ways to Contribute

- **Report a bug** — open an issue using the bug report template.
- **Request a feature** — open an issue using the feature request template, or start a Discussion for open-ended ideas.
- **Improve documentation** — docs PRs are always welcome, including small fixes (typos, broken links).
- **Submit code** — see [Pull Requests](#pull-requests) below.
- **Review PRs** — non-Maintainer reviews are valued and visible to Maintainers.

## Before Opening a Large PR

For non-trivial changes (new features, API changes, refactors touching multiple files), open an issue or Discussion first to align on approach. This avoids wasted work if the direction needs adjustment. Trivial changes (typos, small bug fixes, dependency bumps) can go straight to a PR.

## Development Setup

Each repository documents its own setup in its `README.md`. As a general rule, you will need:

- A recent version of the repository's primary language toolchain (see the repo's `README` for specifics)
- `git` configured with a signing key (see [Signed Commits](#signed-commits))
- The ability to run the repository's test suite locally

## Branching and Commits

- Work in a feature branch off `main`. Name it descriptively: `fix/<short-description>`, `feat/<short-description>`, `docs/<short-description>`.
- Write [conventional commit](https://www.conventionalcommits.org/) messages where the repository uses them (most do). Common prefixes: `feat:`, `fix:`, `docs:`, `chore:`, `refactor:`, `test:`, `ci:`.
- Keep commits focused. Squash noisy work-in-progress commits before requesting review.
- Rebase on `main` rather than merging `main` into your branch, unless the repository specifies otherwise.

## Pull Requests

1. **Fork** the repository (external contributors) or push a branch (Maintainers).
2. **Open a PR** against `main`. Fill out the PR template.
3. **Pass CI.** All required checks must be green. If a check fails for reasons unrelated to your change, comment on the PR — do not force-merge.
4. **Address review feedback.** Push additional commits; squash on merge.
5. **Get approval.** PRs require at least one approving review from a Maintainer who is not the author. Some files (defined in `CODEOWNERS`) require additional reviewers.
6. **Merge.** Maintainers merge using "squash and merge" by default unless the repository specifies otherwise.

### What Maintainers Look For

- The change does what the PR description says it does.
- Tests cover new behavior and don't regress existing behavior.
- Public APIs are documented.
- Breaking changes are called out explicitly and follow the repository's deprecation policy.
- Dependencies added are necessary, actively maintained, and license-compatible.

### Review Turnaround

Maintainers aim to provide an initial response within `<5 business days>`. If your PR has been waiting longer with no activity, leave a polite comment or @-mention a Maintainer.

## Style and Quality

Each repository defines its own linting, formatting, and test conventions, enforced via CI. Run the repository's lint and test commands locally before pushing — most repos provide a `make check`, `npm run check`, or equivalent.

## Releases

Releases are cut by repository Release Managers (see [Governance §7](./GOVERNANCE.md)). If you need a release of a merged change, comment on the relevant issue or PR.

## Getting Help

- **General questions** — open a Discussion in the relevant repository.
- **Bug reports** — open an issue using the bug report template.
- **Maintainer coordination** — see the channels listed in [Governance §10](./GOVERNANCE.md).

## Recognition

Contributors are recognized in repository release notes and, for sustained contributions, may be invited to become Maintainers per the process in [Governance §3.2](./GOVERNANCE.md).

---

Thank you for contributing.