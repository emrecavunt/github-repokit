# Security Policy

## Supported versions

The latest release (and `main`) is supported. This is a Terraform module
library: once you pin a `?ref=`, keeping that pin current is on you.
Dependabot config ships in `.github/dependabot.yml` for Actions and
Terraform provider updates.

## Reporting a vulnerability

Report vulnerabilities privately via
[GitHub Security Advisories](https://github.com/emrecavunt/github-repokit/security/advisories/new)
rather than opening a public issue. You should get a response within a week.

Do not file a public issue for:

- leaked tokens, keys, or service-account credentials
- overly broad GitHub, AWS, or GCP IAM bindings
- workflow permission escalation
- branch-protection bypasses

## What ships with this repo

- Terraform `fmt` and `validate` on every PR and `main` (`ci.yml`)
- CodeQL on GitHub Actions workflows, every PR and weekly (`codeql.yml`)
- Dependency review blocking known-vulnerable Actions on PRs
  (`dependency-review.yml`)
- Trivy config scan in `make check` (and in CI when Trivy is available)
- Least-privilege workflow permissions (`contents: read` on CI)
- Keyless AWS (`modules/github-aws-oidc`) and GCP
  (`modules/github-wif-oidc`) paths so no long-lived cloud key needs to
  live in GitHub Actions
- Branch protection, signed commits, and CODEOWNERS as first-class
  module inputs
