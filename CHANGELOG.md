# Changelog

All notable changes to this project are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and versions follow
[Semantic Versioning](https://semver.org/). Pushes to `main` cut a release
via `semantic-release` (see `.github/workflows/release.yml`).

## [Unreleased]

### Added

- `modules/github-aws-oidc` for GitHub Actions IAM OIDC, scoped to
  trusted repositories, with optional Secrets Manager / SSM read access
- Public release of the GitHub repository and GCP WIF/OIDC bootstrap
  modules, with copy-ready Terragrunt examples
- Canonical consumer layout: `bootstrap/github/repository` (settings)
  and `bootstrap/github/actions` (environments)
- MIT license, security policy, CodeQL, dependency review, and Dependabot
- Repository visibility, topics, homepage, issues/wiki flags, and
  Dependabot vulnerability alerts as first-class module inputs

### Changed

- `bootstrap/github/actions` no longer requires AWS or GCP. Cloud
  identity is an optional `bootstrap/<provider>/identity` add-on; Actions
  variables are wired from environment outputs after identity is applied
- README, module docs, and Terraform descriptions rewritten to lead with
  the per-repo contract, optional identity, and library boundaries

### Fixed

- Release job now runs Node.js 26 with pnpm. semantic-release 25 requires
  Node `^22.14.0` or `>= 24.10.0`, so the previous Node 20 runner failed.