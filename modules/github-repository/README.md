# github-repository

Per-repository GitHub governance: settings, team and collaborator access,
branch protection, CODEOWNERS, environments, and Actions variables.

This module does not write workflow YAML. It does not manage the GitHub
organization. Use it twice in a consumer: once for settings, once for
environments.

## What it manages

- Optional `github_repository` settings (visibility, topics, homepage,
  issues, wiki, Dependabot alerts, delete-branch-on-merge,
  `archive_on_destroy`)
- Team assignments when `owner_is_organization = true`
- User collaborator permissions. The repository owner is omitted
  automatically; GitHub rejects adding the owner as a collaborator
- Branch protection (signed commits, reviews, required checks).
  Organization owners use REST v3, including app push restrictions.
  User-owned repositories use GraphQL. Pattern is typically an exact
  branch name
- `.github/CODEOWNERS` as a managed file
- GitHub environments, including protected production environments
- Actions variables at environment scope, and optionally at repo scope
  (`write_repository_actions_variables`)

## Organization vs user-owned repositories

Set `owner_is_organization` to match the GitHub owner:

| Owner | `owner_is_organization` | Teams | Branch protection |
| ----- | ----------------------- | ----- | ----------------- |
| Organization | `true` (default) | Applied | REST v3 |
| User | `false` | Rejected | GraphQL |

A user-owned public repository cannot use `github_branch_protection_v3`
and cannot add the owner as a collaborator. This repository's
self-bootstrap sets `owner_is_organization = false`.

## Existing repositories

When `manage_repository_settings = true` (default `false`) and
`import_existing_repository = true` (default), the module imports
`github_repository.settings[0]` on first apply so you do not get
`422 name already exists`. Set `import_existing_repository = false` only
when this stack should create a brand-new repository.

On module versions without that import block, run a one-time import:

```bash
terragrunt import 'github_repository.settings[0]' <repo-name>
```

## Consumer layout

Consumer repos create two stacks that both source this module:

```text
bootstrap/github/repository/   # manage_repository_settings = true
bootstrap/github/actions/      # manage_repository_settings = false
```

Keep settings, teams, branch protection, and CODEOWNERS on `repository`.
Keep `github_environment_configs` on `actions`. The actions stack does not
require AWS or GCP. Optional identity lives under
`bootstrap/aws/identity` or `bootstrap/gcp/identity`.

## Environments

Prefer `github_environment_configs` for per-environment variables and
protection. The older `github_environments` plus `github_actions_variables`
pair still works; matching names in `github_environment_configs` win.
