# Changelog

All notable changes to this project are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and versions follow
[Semantic Versioning](https://semver.org/). Releases are cut by
`semantic-release` on `main` (see `.github/workflows/release.yml`).

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