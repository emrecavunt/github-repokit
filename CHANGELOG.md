# Changelog

All notable changes to this project are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and versions follow
[Semantic Versioning](https://semver.org/). Pushes to `main` cut a release
via `semantic-release` (see `.github/workflows/release.yml`).

## [Unreleased]

### Added

- Agent plugin `github-repokit` with four skills (`github-repokit-repository`,
  `github-repokit-actions`, `github-repokit-aws-oidc`, `github-repokit-gcp-wif`),
  Agent Plugins 1.0 + Claude Code dual manifests, hosted GitHub MCP, and a
  hook that denies `terraform` / `terragrunt` / `tofu apply`
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

- Dependabot groups GitHub Actions and npm minor/patch updates; Terraform
  provider major constraint bumps are ignored. Raising a provider floor is
  a planned `BREAKING CHANGE`, not a bot merge
- `modules/github-aws-oidc` accepts AWS provider 5.x and 6.x
  (`>= 5.0, < 7.0`); `modules/github-wif-oidc` accepts Google provider
  6.x–8.x (`>= 6.0, < 9.0`)
- CI pins `actions/checkout` v7.0.1, `hashicorp/setup-terraform` v4.0.1,
  `actions/dependency-review-action` v5.0.0, and
  `amannn/action-semantic-pull-request` v6.1.1 (Node 24 runtimes)
- `bootstrap/github/actions` no longer requires AWS or GCP. Cloud
  identity is an optional `bootstrap/<provider>/identity` add-on; Actions
  variables are wired from environment outputs after identity is applied
- README, module docs, and Terraform descriptions rewritten to lead with
  the per-repo contract, optional identity, and library boundaries

### Fixed

- Release job now runs Node.js 26 with pnpm. semantic-release 25 requires
  Node `^22.14.0` or `>= 24.10.0`, so the previous Node 20 runner failed
- `modules/github-repository` supports organization and user-owned
  repositories via `owner_is_organization`. Organizations keep REST v3
  branch protection and team assignments. User-owned repos use GraphQL
  protection, reject `teams`, and never add the owner as a collaborator