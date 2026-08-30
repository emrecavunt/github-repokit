# github-bootstrapper

[![CI](https://github.com/emrecavunt/github-bootstrapper/actions/workflows/ci.yml/badge.svg)](https://github.com/emrecavunt/github-bootstrapper/actions/workflows/ci.yml)
[![CodeQL](https://github.com/emrecavunt/github-bootstrapper/actions/workflows/codeql.yml/badge.svg)](https://github.com/emrecavunt/github-bootstrapper/actions/workflows/codeql.yml)
[![Release](https://img.shields.io/github/v/release/emrecavunt/github-bootstrapper?include_prereleases&sort=semver)](https://github.com/emrecavunt/github-bootstrapper/releases)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

Terraform modules that put GitHub repository governance in the repo itself:
settings, team and collaborator access, branch protection, CODEOWNERS, Actions
environments, and keyless GCP identity for GitHub Actions.

Clone it, point Terragrunt at a module, and each product repo can own its
GitHub configuration the same way it owns its application code. Organization
membership, billing, and org-wide policy stay elsewhere — this repo is
deliberately per-repository.

## What's in the box

- **`modules/github-repository`**: one repo's settings, team/user access,
  branch protection (signed commits, reviews, required checks), CODEOWNERS,
  GitHub environments, and Actions variables (per-environment or repo-scoped)
- **`modules/github-wif-oidc`**: GCP Workload Identity Federation for GitHub
  Actions — a Terraform apply service account, project IAM, and optional
  project-local WIF pool/provider. No long-lived JSON key in CI
- **`examples/repository-consumer`**: a copy-ready Terragrunt split —
  `gcp/` first (identity), then `github/repository` (settings) and
  `github/actions` (environments + variables that read identity outputs)
- **`bootstrap/github`**: this repository managing itself with the same module
- **A Makefile front-end**: `make` lists everything, `make check` is what CI
  runs
- **CI**: Terraform `fmt` + `validate` on every PR, conventional PR titles
- **Scans**: CodeQL on Actions workflows, dependency review on PRs, Trivy
  via `make check`
- **Releases**: conventional commits on `main` cut a semver tag (`vX.Y.Z`)
  and a GitHub Release via `semantic-release`
- **Dependabot** for GitHub Actions and Terraform providers

The catch: this does **not** write workflow YAML and does **not** manage the
GitHub organization. Workflows stay in `.github/workflows/` of each consumer.
Org-level teams, rulesets, and SSO belong in a separate org stack.

## Quickstart

Requires [Terraform](https://developer.hashicorp.com/terraform/install) `>= 1.7`
and [Terragrunt](https://terragrunt.gruntwork.io/). A `GITHUB_TOKEN` with
`repo` and `admin:org` (for team assignments) is enough for the GitHub
module. The WIF module needs a GCP credential that can create service
accounts and IAM bindings.

```bash
git clone https://github.com/emrecavunt/github-bootstrapper.git
cd github-bootstrapper
make check
```

`make` (or `make help`) lists every target. The ones you'll reach for:

| Target           | What it does                                          |
| ---------------- | ----------------------------------------------------- |
| `make check`     | Format + validate + lint + Trivy (what CI runs)       |
| `make fmt`       | `terraform fmt` and `terragrunt hcl format`           |
| `make validate`  | Validate each module and the `bootstrap/` stack       |
| `make tg-plan`   | Plan the self-bootstrap stack                         |
| `make apply`     | Apply the self-bootstrap stack                        |

## Per-repository usage

Each product or service repo keeps a small Terragrunt stack under
`bootstrap/github`. Split it the same way agents should create it:

- **`bootstrap/github/repository`** — settings, teams, branch protection,
  CODEOWNERS (`manage_repository_settings = true`)
- **`bootstrap/github/actions`** — environments and Actions variables
  (`manage_repository_settings = false`)

Both source this module by tag. Repository stack:

```hcl
terraform {
  source = "git::https://github.com/emrecavunt/github-bootstrapper.git//modules/github-repository?ref=v1.0.0"
}

inputs = {
  repo_name   = "my-service"
  description = "Example service"
  visibility  = "private"

  users = {
    maintainer = {
      username   = "your-github-username"
      permission = "admin"
    }
  }

  teams = {
    platform = {
      slug       = "platform-engineers"
      permission = "push"
    }
  }

  branch_protection_rules = {
    main = {
      pattern                         = "main"
      require_signed_commits          = true
      require_code_owner_reviews      = true
      required_approving_review_count = 1
      required_status_checks          = true
      required_status_check_contexts  = ["verify"]
    }
  }

  codeowners = {
    "*" = ["@your-org/platform-engineers"]
  }

  write_repository_actions_variables = false
  manage_repository_settings         = true
  delete_branch_on_merge             = true
}
```

Actions stack (`bootstrap/github/actions`) — same module, environments only:

```hcl
inputs = {
  repo_name = "my-service"

  manage_repository_settings         = false
  write_repository_actions_variables = false

  github_environment_configs = {
    dev = {
      variables = {
        GOOGLE_PROJECT                 = "my-service-dev"
        GCP_WORKLOAD_IDENTITY_PROVIDER = "projects/111111111111/locations/global/workloadIdentityPools/github/providers/github"
        GCP_TERRAFORM_SA               = "tf-apply@my-service-dev.iam.gserviceaccount.com"
      }
    }
    prod = {
      protected           = true
      can_admins_bypass   = false
      prevent_self_review = true
      variables = {
        GOOGLE_PROJECT                 = "my-service-prod"
        GCP_WORKLOAD_IDENTITY_PROVIDER = "projects/222222222222/locations/global/workloadIdentityPools/github/providers/github"
        GCP_TERRAFORM_SA               = "tf-apply@my-service-prod.iam.gserviceaccount.com"
      }
    }
  }
}
```

When `manage_repository_settings = true` and the GitHub repo already exists,
the module imports `github_repository.settings[0]` on first apply
(`import_existing_repository = true`, default). Set that input to `false`
only when this stack should create a new repository.

Legacy compatibility remains available:

- `github_environments` + `github_actions_variables` (same variables for
  every environment)
- `github_environment_configs` overrides legacy values for matching
  environment names

## Shared WIF / OIDC usage

Use `modules/github-wif-oidc` so each infra repo does not copy a local
identity module. Apply it **before** the GitHub env-var stack so Actions
can reference the provider and service account.

```hcl
terraform {
  source = "git::https://github.com/emrecavunt/github-bootstrapper.git//modules/github-wif-oidc?ref=v1.0.0"
}

inputs = {
  service_account_project_id   = "my-service-dev"
  service_account_id           = "github-actions"
  service_account_display_name = "GitHub Actions"
  github_owner                 = "your-org"
  github_repositories          = ["your-org/my-service"]
  create_project_wif_provider  = true

  target_project_roles = {
    "my-service-dev" = [
      "roles/viewer",
    ]
  }
}
```

WIF mode:

- `create_project_wif_provider = false` (default): requires
  `workload_identity_pool_name` and `workload_identity_provider_name`
- `create_project_wif_provider = true`: creates the pool and provider in
  `service_account_project_id`

A working two-stack walkthrough lives in
[`examples/repository-consumer`](examples/repository-consumer/README.md).

## Self-bootstrap

This repository can manage its own GitHub settings:

```bash
export GITHUB_OWNER=emrecavunt
export GITHUB_TOKEN=...   # repo admin on emrecavunt/github-bootstrapper

cd bootstrap/github
make tg-init
make tg-import-repo-settings REPO_NAME=github-bootstrapper
make tg-plan
make apply
```

## Layout

```
modules/github-repository/   # per-repo GitHub governance
modules/github-wif-oidc/     # GCP OIDC / WIF for GitHub Actions
examples/repository-consumer/
  gcp/identity/              # apply first
  github/repository/         # settings, protection, CODEOWNERS
  github/actions/            # environments + Actions variables
bootstrap/github/
  repository/                # this repo, managing itself
.github/workflows/           # ci, codeql, dependency-review, release
Makefile                     # the front-end: run `make`
```

## Versioning

Pushes to `main` run `semantic-release`. Conventional commits drive the bump:

| Commit                         | Version |
| ------------------------------ | ------- |
| `feat:`                        | minor   |
| `fix:`                         | patch   |
| `feat!:` or `BREAKING CHANGE:` | major   |

Pin consumers to a published tag (`?ref=v1.0.0`), not `main`.

## Security

See [SECURITY.md](SECURITY.md). In short: report privately, pin module
versions, prefer WIF over stored cloud keys, and keep production GitHub
environments `protected = true`.

## License

[MIT](LICENSE) © Emre Cavunt
